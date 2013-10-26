guard :rspec, spec_paths: ["specifications"] do
  watch(%r{^specifications/.+_spec\.rb$})
  watch(%r{^library/(.+)\.rb$})           { |m| "specifications/#{m[1]}_spec.rb" }
  watch('specifications/spec_helper.rb')  { "spec" }
end

