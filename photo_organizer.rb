#!/usr/bin/env ruby

require_relative 'lib/photo_analyzer'

def main
  if ARGV.length != 3
    puts "Usage: ruby photo_organizer.rb <chemin_source> <chemin_uniques> <chemin_duplicatas>"
    puts ""
    puts "Arguments:"
    puts "  chemin_source    : Chemin absolu du dossier à analyser"
    puts "  chemin_uniques   : Chemin absolu pour les photos uniques"
    puts "  chemin_duplicatas: Chemin absolu pour les photos dupliquées"
    exit 1
  end

  source_path = ARGV[0]
  unique_path = ARGV[1]
  duplicate_path = ARGV[2]

  puts "🚀 Démarrage de l'organisateur de photos"
  puts "📁 Source: #{source_path}"
  puts "✨ Photos uniques: #{unique_path}"
  puts "🔄 Photos dupliquées: #{duplicate_path}"
  puts ""

  begin
    analyzer = PhotoAnalyzer.new(source_path, unique_path, duplicate_path)
    analyzer.analyze_and_organize
  rescue => e
    puts "❌ Erreur: #{e.message}"
    exit 1
  end

  puts ""
  puts "🎉 Organisation terminée avec succès!"
end

main if __FILE__ == $0
