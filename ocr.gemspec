# frozen_string_literal: true

require_relative "lib/ocr/version"

Gem::Specification.new do |spec|
  spec.name          = "ocr"
  spec.version       = Ocr::VERSION
  spec.authors       = ["Ravi Shankar Singhal"]
  spec.email         = ["ravi.singhal2308@gmail.com"]

  spec.summary       = "A lightweight Ruby gem for extracting text from images using OCR."
  spec.description   = "OCR is a Ruby gem that allows you to easily extract text from image files (JPG, PNG, PDF) using Tesseract OCR engine. It provides a simple, intuitive interface for integrating OCR capabilities into your Ruby or Rails applications."
  spec.homepage      = "https://github.com/RaviShankarSinghal/ocr_gem"
  spec.license       = "MIT"

  spec.required_ruby_version = ">= 2.6.0"

  spec.metadata = {
    "homepage_uri"   => spec.homepage,
    "source_code_uri" => "https://github.com/RaviShankarSinghal/ocr_gem",
    "changelog_uri"   => "https://github.com/RaviShankarSinghal/ocr_gem/blob/main/CHANGELOG.md",
    "documentation_uri" => "https://rubydoc.info/gems/ocr"
  }

  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .circleci appveyor])
    end
  end

  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Common dependencies for OCR-based Ruby gems
  spec.add_dependency "rtesseract", "~> 2.0"      # Ruby wrapper for Tesseract OCR
  spec.add_dependency "mini_magick", "~> 4.11"    # Image preprocessing support

  # Development dependencies
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "rake", "~> 13.0"
end
