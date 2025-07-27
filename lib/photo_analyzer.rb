require 'mini_exiftool'
require 'dhash-vips'
require 'csv'
require 'fileutils'
require 'pathname'
require 'digest'

class PhotoAnalyzer
  SUPPORTED_EXTENSIONS = %w[.jpg .jpeg .png .tiff .tif .bmp .gif].freeze

  attr_reader :source_path, :unique_path, :duplicate_path, :photos_data, :hash_registry

  def initialize(source_path, unique_path, duplicate_path)
    @source_path = Pathname.new(source_path)
    @unique_path = Pathname.new(unique_path)
    @duplicate_path = Pathname.new(duplicate_path)
    @photos_data = []
    @hash_registry = {}

    validate_paths
    create_output_directories
  end

  def analyze_and_organize
    puts "🔍 Analyse des photos dans: #{@source_path}"
    scan_photos
    export_to_csv
    puts "✅ Analyse terminée. #{@photos_data.length} photos traitées."
  end

  private

  def validate_paths
    raise "Le chemin source n'existe pas: #{@source_path}" unless @source_path.exist?

    [@unique_path, @duplicate_path].each do |path|
      FileUtils.mkdir_p(path) unless path.exist?
    end
  end

  def create_output_directories
    FileUtils.mkdir_p(@unique_path)
    FileUtils.mkdir_p(@duplicate_path)
  end

  def scan_photos
    @source_path.find do |file_path|
      next unless file_path.file?
      next unless supported_image?(file_path)

      process_photo(file_path)
    end
  end

  def supported_image?(file_path)
    SUPPORTED_EXTENSIONS.include?(file_path.extname.downcase)
  end

  def process_photo(file_path)
    puts "📸 Traitement: #{file_path.relative_path_from(@source_path)}"

    photo_info = extract_photo_info(file_path)
    image_hash = calculate_image_hash(file_path)

    photo_info[:image_hash] = image_hash
    @photos_data << photo_info

    organize_photo(file_path, photo_info, image_hash)
  rescue => e
    puts "❌ Erreur lors du traitement de #{file_path}: #{e.message}"
  end

  def extract_photo_info(file_path)
    relative_path = file_path.relative_path_from(@source_path)
    file_type = file_path.extname.upcase.delete('.')
    filename = file_path.basename.to_s
    photo_date = extract_photo_date(file_path)

    {
      relative_path: relative_path.to_s,
      file_type: file_type,
      filename: filename,
      photo_date: photo_date,
      original_path: file_path.to_s
    }
  end

  def extract_photo_date(file_path)
    # Essayer d'abord les métadonnées EXIF
    begin
      exif = MiniExiftool.new(file_path.to_s)
      if exif.date_time_original
        return Time.parse(exif.date_time_original.to_s)
      elsif exif.create_date
        return Time.parse(exif.create_date.to_s)
      end
    rescue => e
      puts "⚠️  Impossible de lire les métadonnées EXIF pour #{file_path}: #{e.message}"
    end

    # Fallback sur la date de modification du fichier
    file_path.mtime
  end

  def calculate_image_hash(file_path)
    # Utiliser dhash-vips pour un hash perceptuel fiable
    DHashVips::DHash.calculate(file_path.to_s)
  rescue => e
    puts "⚠️  Impossible de calculer le hash pour #{file_path}: #{e.message}"
    # Fallback sur un hash MD5 du contenu
    Digest::MD5.hexdigest(File.read(file_path))
  end

  def organize_photo(file_path, photo_info, image_hash)
    photo_date = photo_info[:photo_date]
    year = photo_date.year.to_s
    month = format('%02d', photo_date.month)
    day = format('%02d', photo_date.day)

    if @hash_registry.key?(image_hash)
      # Photo dupliquée
      move_duplicate_photo(file_path, photo_info, image_hash, year, month, day)
    else
      # Nouvelle photo unique
      @hash_registry[image_hash] = { count: 1, original_path: file_path.to_s }
      move_unique_photo(file_path, photo_info, year, month, day)
    end
  end

  def move_unique_photo(file_path, photo_info, year, month, day)
    target_dir = @unique_path / year / month / day
    FileUtils.mkdir_p(target_dir)

    target_file = target_dir / photo_info[:filename]
    target_file = ensure_unique_filename(target_file)

    FileUtils.mv(file_path, target_file)
    puts "✅ Déplacé vers: #{target_file.relative_path_from(@unique_path)}"
  end

  def move_duplicate_photo(file_path, photo_info, image_hash, year, month, day)
    @hash_registry[image_hash][:count] += 1
    increment = @hash_registry[image_hash][:count]

    hash_short = image_hash.to_s[0..7]  # Utiliser les 8 premiers caractères du hash
    target_dir = @duplicate_path / year / month / day / hash_short
    FileUtils.mkdir_p(target_dir)

    name_without_ext = File.basename(photo_info[:filename], '.*')
    extension = File.extname(photo_info[:filename])
    new_filename = "#{name_without_ext}_#{increment}#{extension}"

    target_file = target_dir / new_filename

    FileUtils.mv(file_path, target_file)
    puts "🔄 Duplicata déplacé vers: #{target_file.relative_path_from(@duplicate_path)}"
  end

  def ensure_unique_filename(target_file)
    counter = 1
    original_target = target_file

    while target_file.exist?
      name_without_ext = File.basename(original_target, '.*')
      extension = File.extname(original_target)
      new_name = "#{name_without_ext}_#{counter}#{extension}"
      target_file = original_target.dirname / new_name
      counter += 1
    end

    target_file
  end

  def export_to_csv
    csv_path = @unique_path / 'analyse.csv'

    CSV.open(csv_path, 'w', headers: true) do |csv|
      csv << ['chemin_relatif', 'type_fichier', 'nom_fichier', 'date_photo', 'hash_image', 'chemin_original']

      @photos_data.each do |photo|
        csv << [
          photo[:relative_path],
          photo[:file_type],
          photo[:filename],
          photo[:photo_date].strftime('%Y-%m-%d %H:%M:%S'),
          photo[:image_hash],
          photo[:original_path]
        ]
      end
    end

    puts "📊 Rapport CSV exporté vers: #{csv_path}"
  end
end
