/* 
 * Copyright (C) 2011-2013 Daiki Ueno <ueno@gnu.org>
 * Copyright (C) 2011-2013 Red Hat, Inc.
 * 
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA
 * 02110-1301, USA.
 */
using Gee;

public class DictionaryMetadata : Object {
    public string id { get; construct set; }
    public string filename { get; construct set; }
    public string name { get; construct set; }
    public string description { get; construct set; }

    public string encoding { get; construct set; default = "EUC-JP"; }
    public bool default_enabled { get; construct set; default = false; }

    public DictionaryMetadata.from_json_object (Json.Object object) {
        var id = object.get_string_member ("id");
        var filename = object.get_string_member ("filename");
        var name = object.get_string_member ("name");
        var description = object.get_string_member ("description");

        var default_enabled = false;
        if (object.has_member ("default_enabled"))
            default_enabled = object.get_boolean_member ("default_enabled");

        var encoding = "EUC-JP";
        if (object.has_member ("encoding")) {
            encoding = object.get_string_member ("encoding");
        }

        Object (id: id,
                filename: filename,
                name: name,
                description: description,
                default_enabled: default_enabled,
                encoding: encoding);
    }
}

public class DictionaryRegistry : Object {
    Map<string,DictionaryMetadata> available_metadata =
        new HashMap<string,DictionaryMetadata> ();
    Gee.List<string> available = new ArrayList<string> ();

    void load_metadata_from_stream (InputStream stream) {
        var parser = new Json.Parser ();
        try {
            parser.load_from_stream (stream);
        } catch (GLib.Error e) {
            error ("failed to parse JSON: %s", e.message);
        }

        var root = parser.get_root ();

        if (root.get_node_type () != Json.NodeType.ARRAY) {
            error ("malformed format of dictionaries list: toplevel");
        }
        var array = root.get_array ();

        for (var i = 0; i < array.get_length (); i++) {
            var node = array.get_element (i);

            if (node.get_node_type () != Json.NodeType.OBJECT) {
                warning ("malformed format of dictionaries list: child object");
                continue;
            }

            var object = node.get_object ();
            var metadata = new DictionaryMetadata.from_json_object (object);

            if (FileUtils.test (metadata.filename, FileTest.EXISTS)) {
                available_metadata.set (metadata.id, metadata);
                available.add (metadata.id);
            }
        }
    }

    public DictionaryMetadata[] list_available () {
        var result = new ArrayList<DictionaryMetadata> ();
        foreach (var id in available) {
            result.add (get_metadata (id));
        }
        return result.to_array ();
    }

    public DictionaryMetadata? get_metadata (string id) {
        return available_metadata.get (id);
    }

    public DictionaryRegistry () {
        try {
            var stream = resources_open_stream (
                "/org/freedesktop/ibus/engine/kkc/dictionaries.json",
                ResourceLookupFlags.NONE);
            load_metadata_from_stream (stream);
        } catch (GLib.Error e) {
            error ("can't load dictionaries list from resource: %s", e.message);
        }

        var file = File.new_for_path (Path.build_filename (
                                          Environment.get_user_config_dir (),
                                          Config.PACKAGE_NAME,
                                          "dictionaries.json"));
        if (file.query_exists ()) {
            try {
                var stream = file.read ();
                load_metadata_from_stream (stream);
            } catch (GLib.Error e) {
                warning ("%s exists, but cannot read: %s",
                         file.get_path (),
                         e.message);
            }
        }
    }
}
