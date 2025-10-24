# frozen_string_literal: true

require_relative "lib/ocr/version"

Gem::Specification.new do |spec|
  spec.name          = "pdf_ocr"
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
    "documentation_uri" => "https://rubydoc.info/gems/pdf_ocr/#{spec.version}"
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
  # Runtime dependencies
  spec.add_runtime_dependency "pdf-reader"
  spec.add_runtime_dependency "mini_magick"
  spec.add_runtime_dependency "rtesseract"

  # Development dependencies
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "byebug"

end
