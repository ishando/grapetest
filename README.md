test app with grape, grape-entity and sequel

```bash
sudo apt install libpq-dev
gem install
```

### migration

```bash
bundle exec sequel -m db/migrations/ postgres://user:pass@localhost/scentre
```

### running

```bash
bundle exec rackup
```

### endpoints

- http://localhost:9292/incomplete
- http://localhost:9292/complete
- http://localhost:9292/ping
