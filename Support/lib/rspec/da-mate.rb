LAST_RUN_FILENAME = "/tmp/textmate_rspec_last_run"

def run_rspec(*args)
  Dir.chdir ENV["TM_PROJECT_DIRECTORY"]
  save_as_last_run(args)
  seed = rand(65535)
  args += %W(--format textmate --order rand:#{seed})
  remove_rbenv_from_env
  if binstub_available?
    system("bin/rspec", *args)
  elsif zeus_available?
    system("zeus", "rspec", *args)
  else
    puts "Neither binstubs nor zeus available, falling back to bundle exec ...<br>"
    system("bundle", "exec", "rspec", *args)
  end
end

def run_rspec_in_terminal(*args)
  require "shellwords"
  
  shellcmd = "cd #{Shellwords.escape ENV["TM_PROJECT_DIRECTORY"]}; "
  shellcmd << "#{binstub_available? ? 'bin/rspec' : 'bundle exec rspec'} " + args.map{ |arg| Shellwords.escape(arg) }.join(" ")
   
  applescript = %{
    tell application "Terminal" to activate
    tell application "System Events"
    	tell process "Terminal" to keystroke "t" using command down
    end tell
    tell application "Terminal"
      do script "#{shellcmd.gsub('\\', '\\\\\\\\').gsub('"', '\\"')}" in the last tab of window 1
    end tell
  }
  
   open("|osascript", "w") { |io| io << applescript }
end

def rerun_rspec
  run_rspec *load_last_run_args
end

def rerun_rspec_in_terminal
  run_rspec_in_terminal *load_last_run_args
end

def save_as_last_run(args)
  File.open(LAST_RUN_FILENAME, "w") do |f|
    f.puts Marshal.dump(args)
  end
end

def load_last_run_args
  Marshal.load(File.read(LAST_RUN_FILENAME))
end

def binstub_available?
  File.exist?(ENV["TM_PROJECT_DIRECTORY"] + "/bin/rspec")
end

def zeus_available?
  File.exist?(ENV["TM_PROJECT_DIRECTORY"] + "/.zeus.sock")
end

# See https://github.com/sstephenson/rbenv/issues/121#issuecomment-12735894
def remove_rbenv_from_env
  rbenv_root = `rbenv root 2>/dev/null`.chomp

  unless rbenv_root.empty?
    re = /^#{Regexp.escape rbenv_root}\/(versions|plugins|libexec)\b/
    paths = ENV["PATH"].split(":")
    paths.reject! {|p| p =~ re }
    ENV["PATH"] = paths.join(":")
    
    ENV.each{ |name, value| ENV[name] = nil if name =~ /^RBENV_/ }
  end
end