# Nominatim 3.0.1 Docker

Working container for [Nominatim](https://github.com/twain47/Nominatim).
Uses Ubuntu 16.04 and PostgreSQL 9.5

# Country

To set different country should be used you can set `PBF_DATA` on build.

1. Add the OSM import file **my-map-latest.osm.pbf** to the root directory (or create a symbolic link with this name that points to the OSM import fiile).

2. Configure incrimental update. By default CONST_Replication_Url configured for Monaco.
If you want a different update source, you will need to declare `CONST_Replication_Url` in local.php. Documentation [here] (https://github.com/twain47/Nominatim/blob/master/docs/Import_and_update.md#updates). For example, to use the daily country extracts diffs for Gemany from geofabrik add the following:

  ```
  @define('CONST_Replication_Url', 'http://planet.osm.org/replication/day/');
  ```
3. Buld the docker image

  ```
  $ docker-compose build
  ```

4. Run

  ```
  docker-compose up
  ```
  If this succeeds, open [http://localhost:8080/](http:/localhost:8080) in a web browser
