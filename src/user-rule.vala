/* 
 * Copyright (C) 2013 Daiki Ueno <ueno@gnu.org>
 * Copyright (C) 2013 Red Hat, Inc.
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
public class UserRule : Kkc.Rule {
    Kkc.Keymap[] overrides;
    Kkc.RuleMetadata parent_metadata;
    string path;

    public UserRule (Kkc.RuleMetadata parent_metadata,
                     string base_dir,
                     string prefix) throws Kkc.RuleParseError {
        var user_rule_path = Path.build_filename (base_dir,
                                                  parent_metadata.name);

        if (!FileUtils.test (user_rule_path, FileTest.IS_DIR)) {
            create_files (parent_metadata,
                          user_rule_path,
                          prefix + ":" + parent_metadata.name);
        }

        var metadata = Kkc.Rule.load_metadata (
            Path.build_filename (user_rule_path, "metadata.json"));
        base (metadata);

        var enum_class = (EnumClass) typeof (Kkc.InputMode).class_ref ();
        overrides = new Kkc.Keymap[enum_class.maximum];
        for (int i = enum_class.minimum; i <= enum_class.maximum; i++) {
            var enum_value = enum_class.get_value (i);
            if (enum_value != null)
                overrides[enum_value.value] = new Kkc.Keymap ();
        }

        this.path = user_rule_path;
        this.parent_metadata = parent_metadata;
    }

    static void create_files (Kkc.RuleMetadata parent_metadata,
                              string path,
                              string name) {
        DirUtils.create_with_parents (path, 448);
        create_metadata (parent_metadata, path, name);
        create_default (parent_metadata, path, "keymap", "default");
        create_default (parent_metadata, path, "keymap", "hiragana");
        create_default (parent_metadata, path, "keymap", "katakana");
        create_default (parent_metadata, path, "keymap", "hankaku-katakana");
        create_default (parent_metadata, path, "keymap", "latin");
        create_default (parent_metadata, path, "keymap", "wide-latin");
        create_default (parent_metadata, path, "keymap", "direct");
        create_default (parent_metadata, path, "rom-kana", "default");
    }

    static void create_metadata (Kkc.RuleMetadata parent_metadata,
                                 string path,
                                 string name)
    {
        var builder = new Json.Builder ();
        builder.begin_object ();
        builder.set_member_name ("name");
        builder.add_string_value (name);
        builder.set_member_name ("description");
        builder.add_string_value (parent_metadata.description);
        builder.set_member_name ("filter");
        builder.add_string_value (parent_metadata.filter);
        builder.end_object ();
        var generator = new Json.Generator ();
        generator.set_pretty (true);
        generator.set_root (builder.get_root ());
        try {
            generator.to_file (
                Path.build_filename (path, "metadata.json"));
        } catch (Error e) {
            error ("can't write metadata for user rule %s: %s",
                   name, e.message);
        }
    }

    static void create_default (Kkc.RuleMetadata parent_metadata,
                                string path,
                                string type,
                                string name) {
        var type_path = Path.build_filename (path, type);
        DirUtils.create_with_parents (type_path, 448);

        var builder = new Json.Builder ();
        builder.begin_object ();
        builder.set_member_name ("include");
        builder.begin_array ();
        builder.add_string_value (parent_metadata.name + "/" + name);
        builder.end_array ();
        builder.end_object ();

        var generator = new Json.Generator ();
        generator.set_pretty (true);
        generator.set_root (builder.get_root ());

        var filename = Path.build_filename (type_path, "%s.json".printf (name));
        generator.to_file (filename);
    }

    public void set_override (Kkc.InputMode input_mode,
                              Kkc.KeyEvent event,
                              string? command) {
        overrides[input_mode].set (event, command);
    }

    public void write_override (Kkc.InputMode input_mode) {
        var enum_class = (EnumClass) typeof (Kkc.InputMode).class_ref ();
        var keymap_name = enum_class.get_value (input_mode).value_nick;
        var keymap_path = Path.build_filename (path, "keymap");
        DirUtils.create_with_parents (keymap_path, 448);

        var builder = new Json.Builder ();
        builder.begin_object ();
        builder.set_member_name ("include");
        builder.begin_array ();
        builder.add_string_value (parent_metadata.name + "/" + keymap_name);
        builder.end_array ();
        builder.set_member_name ("define");
        builder.begin_object ();
        builder.set_member_name ("keymap");
        builder.begin_object ();
        var entries = overrides[input_mode].entries ();
        foreach (var entry in entries) {
            builder.set_member_name (entry.key.to_string ());
            if (entry.command == null)
                builder.add_null_value ();
            else
                builder.add_string_value (entry.command);
        }
        builder.end_object ();
        builder.end_object ();
        builder.end_object ();

        var generator = new Json.Generator ();
        generator.set_pretty (true);
        generator.set_root (builder.get_root ());

        var filename = Path.build_filename (keymap_path,
                                            "%s.json".printf (keymap_name));
        generator.to_file (filename);
    }
}
