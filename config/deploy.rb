# config valid for current version and patch releases of Capistrano
lock "~> 3.19.2"
ask :branch, `git rev-parse --abbrev-ref HEAD`.chomp

set :application, "africa_democracy_hub"
set :repo_url, "git@github.com:eshaam/africa_democracy_hub.git"
set :deploy_to, "/home/deploy/rails/#{fetch :application}"
set :rbenv_ruby, '3.2.6'
set :linked_files, %w{config/database.yml config/master.key}
set :linked_dirs, %w{log tmp/pids tmp/cache tmp/sockets vendor/bundle public/system}
set :puma_threads, [4, 16]
set :puma_workers, 0