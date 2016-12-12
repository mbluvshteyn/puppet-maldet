# Manage Linux Malware Detect configuration files
class maldet::config (
  Hash    $config        = $maldet::config,
  Array   $monitor_paths = $maldet::monitor_paths,
  Hash    $cron_config   = $maldet::cron_config,
  String  $version       = $maldet::version,
  Boolean $daily_scan    = $maldet::daily_scan,
) {

  # Versions of maldet < 1.5 use a different set of
  # config options
  if versioncmp($maldet::version, '1.5') >= 0 {
    $default_config = lookup('maldet::new_config', Hash)
    $merged_config = $default_config + $config
  } else {
    $default_config = lookup('maldet::old_config', Hash)
    $merged_config = $default_config + $config
  }

  file { '/usr/local/maldetect/conf.maldet':
    ensure  => present,
    mode    => '0644',
    owner   => root,
    group   => root,
    content => epp('maldet/conf.maldet.epp', { 'config' => $merged_config }),
  }

  # Allow config overrides for daily cron
  if versioncmp($maldet::version, '1.5') >= 0 {
    file { '/usr/local/maldetect/cron/conf.maldet.cron':
      ensure  => present,
      mode    => '0644',
      owner   => root,
      group   => root,
      content => epp('maldet/conf.maldet.epp', { 'config' => $cron_config }),
    }
  }

  if $facts['service_provider'] == 'redhat' {
    # MONITOR_MODE is commented out by default and can prevent maldet service
    # from starting when using the init based startup script.
    file { '/etc/sysconfig/maldet':
      ensure  => present,
      mode    => '0644',
      owner   => root,
      group   => root,
      content => inline_epp('MONITOR_MODE="<%= $monitor_mode %>"', {'monitor_mode' => $merged_config['default_monitor_mode']}),
    }
  }

  file { '/usr/local/maldetect/monitor_paths':
    ensure  => present,
    mode    => '0644',
    owner   => root,
    group   => root,
    content => join($monitor_paths, "\n"),
  }

  unless $daily_scan {
    file { '/etc/cron.daily/maldet':
      ensure => absent,
    }
  }
}
