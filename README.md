# Rails Documentation Server Support

## Dependencies

* RVM

* `rvm install 2.0.0-p353 -n railsexpress --patch railsexpress`

* `rvm use 2.0.0-p353-railsexpress do gem install bundler -v 1.3.5 --no-rdoc --no-ri`

* `kindlegen` must be in `PATH` ([download](http://www.amazon.com/gp/feature.html?docId=1000765211)))

* `sudo apt-get install imagemagick`, for `convert`, used by the guides generator

* `sudo apt-get install libxslt-dev libxml2-dev` for Nokogiri, present in some Gemfiles

There is no need to have `2.0.0-p353-railsexpress` as default interpreter, the
docs generator uses `rvm 2.0.0-p353-railsexpress do ...` everywhere.

The Ruby and bundler dependencies are not hard, we fix concrete versions because
these are known to work. Ruby and bundler versions are configurable per release,
so this is forward-compatible, just add new versions if needed and configure
their target generator to use them.

## Locale

Make sure the locale is UTF8, in Linux run `locale` and see if the values are
"en_US.UTF-8" in general. In Ubuntu edit the file _/etc/default/locale_ and put

```
LC_ALL=en_US.UTF-8
LANG=en_US.UTF-8
```

## Deployment

Just push to `master`. The cron job in the docs server pulls before invoking
the docs generator.

