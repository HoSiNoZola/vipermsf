##
# This module requires Metasploit: https://metasploit.com/download
# Current source: https://github.com/rapid7/metasploit-framework
##

class MetasploitModule < Msf::Post
  include Msf::Post::File

  def initialize(info = {})
    super(
      update_info(
        info,
        'Name' => 'Linux Gather Container Detection',
        'Description' => %q{
          This module attempts to determine whether the system is running
          inside of a container and if so, which one. This module supports
          detection of Docker, WSL, LXC, Podman and systemd nspawn.
        },
        'License' => MSF_LICENSE,
        'Author' => ['James Otten <jamesotten1[at]gmail.com>'],
        'Platform' => ['linux'],
        'SessionTypes' => ['shell', 'meterpreter']
      )
    )
  end

  # Run Method for when run command is issued
  def run
    container = nil

    # Check for .dockerenv file
    if container.nil? && file?('/.dockerenv')
      container = 'Docker'
    end

    # Check for .dockerinit file
    if container.nil? && file?('/.dockerinit')
      container = 'Docker'
    end

    # Check for /.containerenv file
    if container.nil? && file?('/run/.containerenv')
      container = 'Podman'
    end

    # Check for /dev/lxd/sock file
    if container.nil? && directory?('/dev/lxc')
      container = 'LXC'
    end

    # Check for WSL, as suggested in https://github.com/Microsoft/WSL/issues/423#issuecomment-221627364
    if container.nil? && file?('/proc/sys/kernel/osrelease')
      osrelease = read_file('/proc/sys/kernel/osrelease')
      if osrelease
        case osrelease.tr("\n", ' ')
        when /WSL|Microsoft/i
          container = 'WSL'
        end
      end
    end

    # Check cgroup on PID 1
    if container.nil?
      cgroup = read_file('/proc/1/cgroup')
      if cgroup
        case cgroup.tr("\n", ' ')
        when /docker/i
          container = 'Docker'
        when /lxc/i
          container = 'LXC'
        end
      end
    end

    # Check for the "container" environment variable
    if container.nil?
      container_variable = get_env('container')
      case container_variable
      when 'lxc'
        container = 'LXC'
      when 'systemd-nspawn'
        container = 'systemd nspawn'
      when 'podman'
        container = 'podman'
      end
    end

    if container
      pub_json_result(true,
                      nil,
                      container,
                      self.uuid)
    else
      pub_json_result(true,
                      nil,
                      container,
                      self.uuid)
    end
  end
end
