# Rails Documentation Server Support

## Dependencies

* RVM

* `rvm install 3.3.6`

* `rvm install 3.1.4`

* `rvm install 2.7.6`

* `rvm install 2.5.3`

* `rvm use 2.5.3 do gem install bundler -v 1.16.1 --no-rdoc --no-ri`

* `rvm use 2.5.3 do gem install bundler -v 2.1.4 --no-rdoc --no-ri`

* `rvm use 2.5.3 do gem install bundler -v 2.2.3 --no-rdoc --no-ri`

* `rvm use 2.7.6 do gem install bundler -v 2.2.3 --no-doc`

* `rvm use 3.1.4 do gem install bundler --no-doc`

* `rvm use 3.3.6 do gem install bundler --no-doc`

* `kindlegen` must be in `PATH` ([download](http://www.amazon.com/gp/feature.html?docId=1000765211)))

* Install imagemagick, for `convert`, used by the guides generator
  - Linux: `sudo apt-get install imagemagick`
  - macOS: `brew install imagemagick`

* Nokogiri's dependencies (present in some Gemfiles):
  - Linux: `sudo apt-get install libxslt-dev libxml2-dev`
  - macOS: `brew install libxml2` (see [nokogiri installation instructions](https://nokogiri.org/tutorials/installing_nokogiri.html))

The Ruby and bundler dependencies are not hard, we fix concrete versions because
these are known to work. Ruby and bundler versions are configurable per release,
so this is forward-compatible, just add new versions if needed and configure
their target generator to use them.

## Locale

Make sure the locale is UTF8, in Linux/macOS run `locale` and see if the values are
"en\_US.UTF-8" in general.

In Ubuntu edit the file _/etc/default/locale_ and put

```
LC_ALL=en_US.UTF-8
LANG=en_US.UTF-8
```

## Deployment

Just push to `main`. The cron job in the docs server pulls before invoking
the docs generator.

## Test Suite

In order to run the test suite you need a recent version of minitest:

* `gem install minitest -N`

There are two tasks: The default task, `test`, tests everything except actual
docs generation. The `test:all` task runs the entire suite including doc
generation for a few releases, this one takes about 20 minutes in my laptop.
