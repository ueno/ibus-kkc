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

public class Preferences : Object {
    IBus.Config config;
    DictionaryRegistry registry;

    Map<string,Variant> _default = new HashMap<string,Variant> ();
    Map<string,Variant> current = new HashMap<string,Variant> ();

    public void load () {
        Variant? values = config.get_values ("engine/kkc");
        if (values != null) {
            var iter = values.iterator ();
            Variant? entry = null;
            while ((entry = iter.next_value ()) != null) {
                string name;
                Variant value;
                entry.get ("{sv}", out name, out value);
                current.set (name, value);
            }
        }
    }

    public DictionaryMetadata[] list_available_dictionaries () {
        return registry.list_available ();
    }

    public DictionaryMetadata get_dictionary_metadata (string id) {
        return registry.get_metadata (id);
    }

    public new Variant? @get (string name) {
        Variant? value = current.get (name);
        if (value != null) {
            return value;
        }
        return _default.get (name);
    }

    public new void @set (string name, Variant value) {
        Variant? _value = current.get (name);
        if (_value == null || !_value.equal (value)) {
            _value = _default.get (name);
            if (_value == null || !_value.equal (value)) {
                current.set (name, value);
                config.set_value ("engine/kkc", name, value);
            } else {
                current.unset (name);
                config.unset ("engine/kkc", name);
            }
        }
    }

    public Preferences (IBus.Config config) {
        registry = new DictionaryRegistry ();

        _default.set (
            "user_dictionary",
            new Variant.string (
                Path.build_filename (
                    Environment.get_user_config_dir (),
                    Config.PACKAGE_NAME,
                    "dictionary")));

        ArrayList<string> dictionaries = new ArrayList<string> ();
        foreach (var metadata in list_available_dictionaries ()) {
            if (metadata.default_enabled) {
                dictionaries.add (metadata.id);
            }
        }
        _default.set ("system_dictionaries",
                      new Variant.strv (dictionaries.to_array ()));
        _default.set ("punctuation_style",
                      new Variant.int32 ((int32) Kkc.PunctuationStyle.JA_JA));
        _default.set ("auto_correct",
                      new Variant.boolean (true));
        _default.set ("page_size",
                      new Variant.int32 (10));
        _default.set ("pagination_start",
                      new Variant.int32 (0));
        _default.set ("show_annotation",
                      new Variant.boolean (false));
        _default.set ("initial_input_mode",
                      new Variant.int32 (Kkc.InputMode.HIRAGANA));
        _default.set ("egg_like_newline",
                      new Variant.boolean (false));
        _default.set ("typing_rule",
                      new Variant.string ("default"));
        _default.set ("use_custom_keymap",
                      new Variant.boolean (false));
        _default.set ("keymap",
                      new Variant.string ("jp"));

        this.config = config;
        load ();
        config.value_changed.connect (value_changed_cb);
    }

    public signal void value_changed (string name, Variant value);

    void value_changed_cb (IBus.Config config,
                           string section,
                           string name,
                           Variant value)
    {
        if (section == "engine/kkc") {
            if (value == null ||
                // An empty tuple means that the value was unset.
                value.equal (new Variant.tuple (new Variant[0]))) {
                current.unset (name);
            } else {
                current.set (name, value);
            }
            value_changed (name, value);
        }
    }
}
