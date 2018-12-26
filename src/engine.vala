/* 
 * Copyright (C) 2011-2018 Daiki Ueno <ueno@gnu.org>
 * Copyright (C) 2011-2018 Red Hat, Inc.
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

class KkcEngine : IBus.Engine {
    // Settings are shared among KkcEngine instances.
    static Settings settings;
    static DictionaryRegistry registry;

    // Dictionaries are shared among KkcEngine instances and
    // maintained in the per-class signal handler in main().
    static ArrayList<Kkc.Dictionary> dictionaries;

    // Language model is shared among KkcEngine instances and
    // maintained in the per-class signal handler in main().
    static Kkc.LanguageModel language_model;

    Kkc.Context context;
    IBus.LookupTable lookup_table;
    bool lookup_table_visible;

    bool use_custom_keymap;
    bool show_annotation;

    IBus.Keymap keymap;
    IBus.Property input_mode_prop;
    IBus.PropList prop_list;
    bool properties_registered = false;

    Map<Kkc.InputMode, IBus.Property> input_mode_props =
        new HashMap<Kkc.InputMode, IBus.Property> ();
    Map<Kkc.InputMode, string> input_mode_symbols =
        new HashMap<Kkc.InputMode, string> ();
    Map<string, Kkc.InputMode> name_input_modes =
        new HashMap<string, Kkc.InputMode> ();

    Gtk.Clipboard clipboard;

    construct {
        // Prepare lookup table
        lookup_table = new IBus.LookupTable (LOOKUP_TABLE_LABELS.length,
                                             0, true, true);
        for (var i = 0; i < LOOKUP_TABLE_LABELS.length; i++) {
            var text = new IBus.Text.from_string (LOOKUP_TABLE_LABELS[i]);
            lookup_table.set_label (i, text);
        }

        // Prepare the properties on the lang bar
        prop_list = new IBus.PropList ();
        var props = new IBus.PropList ();
        IBus.Property prop;

        prop = register_input_mode_property (Kkc.InputMode.HIRAGANA,
                                             "InputMode.Hiragana",
                                             _("Hiragana"),
                                             "あ");
        props.append (prop);

        prop = register_input_mode_property (Kkc.InputMode.KATAKANA,
                                             "InputMode.Katakana",
                                             _("Katakana"),
                                             "ア");
        props.append (prop);

        prop = register_input_mode_property (Kkc.InputMode.HANKAKU_KATAKANA,
                                             "InputMode.HankakuKatakana",
                                             _("Halfwidth Katakana"),
                                             "_ｱ");
        props.append (prop);

        prop = register_input_mode_property (Kkc.InputMode.LATIN,
                                             "InputMode.Latin",
                                             _("Latin"),
                                             "_A");
        props.append (prop);

        prop = register_input_mode_property (Kkc.InputMode.WIDE_LATIN,
                                             "InputMode.WideLatin",
                                             _("Wide Latin"),
                                             "Ａ");
        props.append (prop);

        prop = register_input_mode_property (Kkc.InputMode.DIRECT,
                                             "InputMode.Direct",
                                             _("Direct Input"),
                                             "_A");
        props.append (prop);

        prop = new IBus.Property (
            "InputMode",
            IBus.PropType.MENU,
            new IBus.Text.from_string ("あ"),
            null,
            new IBus.Text.from_string (_("Switch input mode")),
            true,
            true,
            IBus.PropState.UNCHECKED,
            props);
        prop_list.append (prop);
        input_mode_prop = prop;

        prop = new IBus.Property (
            "setup",
            IBus.PropType.NORMAL,
            new IBus.Text.from_string (_("Preferences")),
            "gtk-preferences",
            new IBus.Text.from_string (_("Configure Kana Kanji Conversion")),
            true,
            true,
            IBus.PropState.UNCHECKED,
            null);
        prop_list.append (prop);

        // Initialize the context of libkkc.
        context = new Kkc.Context (language_model);

        foreach (var dictionary in dictionaries) {
            context.dictionaries.add (dictionary);
        }

        apply_settings ();
        settings.changed["dictionaries"].connect ((key) => {
                // KkcEngine.dictionaries should be updated separately
                context.dictionaries.clear ();
                foreach (var dictionary in KkcEngine.dictionaries) {
                    context.dictionaries.add (dictionary);
                }
            });

        context.notify["input"].connect (() => {
                update_preedit ();
            });
        context.notify["input-mode"].connect ((s, p) => {
                update_input_mode ();
            });
        context.candidates.populated.connect (() => {
                populate_lookup_table ();
            });
        context.candidates.notify["cursor-pos"].connect (() => {
                set_lookup_table_cursor_pos ();
            });
        context.candidates.selected.connect (() => {
                if (lookup_table_visible) {
                    hide_lookup_table ();
                    hide_auxiliary_text ();
                    lookup_table_visible = false;
                }
            });

        // Initialize clipboard
        clipboard = Gtk.Clipboard.get (Gdk.SELECTION_PRIMARY);
        context.request_selection_text.connect ((e) => {
                clipboard.request_text (
                    (Gtk.ClipboardTextReceivedFunc) set_selection_text);
            });

        update_candidates ();
        update_input_mode ();
    }

    [CCode (instance_pos = 2.1)]
    void set_selection_text (Gtk.Clipboard clipboard, string? text) {
        context.set_selection_text (text);
    }

    void populate_lookup_table () {
        lookup_table.clear ();
        for (int i = (int) context.candidates.page_start;
             i < context.candidates.size;
             i++) {
            var text = new IBus.Text.from_string (
                context.candidates[i].output);
            lookup_table.append_candidate (text);
        }
    }

    void set_lookup_table_cursor_pos () {
        var empty_text = new IBus.Text.from_static_string ("");
        var cursor_pos = context.candidates.cursor_pos;
        if (context.candidates.page_visible) {
            lookup_table.set_cursor_pos (cursor_pos -
                                         context.candidates.page_start);
            update_lookup_table_fast (lookup_table, true);
            var candidate = context.candidates.get ();
            if (show_annotation
                && candidate.annotation != null
                // SKK-JISYO.* has annotations marked as "?" for
                // development purposes.
                && candidate.annotation != "?") {
                var text = new IBus.Text.from_string (
                    candidate.annotation);
                update_auxiliary_text (text, true);
            } else {
                update_auxiliary_text (empty_text, false);
            }
            lookup_table_visible = true;
        } else if (lookup_table_visible) {
            hide_lookup_table ();
            hide_auxiliary_text ();
            lookup_table_visible = false;
        }
    }

    void update_preedit () {
        IBus.Text text;
        uint cursor_pos;
        if (context.segments.cursor_pos >= 0) {
            text = new IBus.Text.from_string (context.segments.get_output ());
            int index = 0;
            int offset = 0;
            for (; index < context.segments.cursor_pos; index++) {
                offset += context.segments[index].output.char_count ();
            }
            text.append_attribute (
                IBus.AttrType.BACKGROUND,
                0x00c8c8f0,
                offset,
                offset + context.segments[index].output.char_count ());
            text.append_attribute (
                IBus.AttrType.FOREGROUND,
                0x00000000,
                offset,
                offset + context.segments[index].output.char_count ());
            cursor_pos = offset;
        } else {
            text = new IBus.Text.from_string (context.input);
            if (text.get_length () > 0 &&
                context.input_cursor_pos >= 0) {
                text.append_attribute (
                    IBus.AttrType.BACKGROUND,
                    0x00000000,
                    context.input_cursor_pos,
                    context.input_cursor_pos + (int) context.input_cursor_width);
                text.append_attribute (
                    IBus.AttrType.FOREGROUND,
                    (uint) 0xffffffff,
                    context.input_cursor_pos,
                    context.input_cursor_pos + (int) context.input_cursor_width);
                cursor_pos = context.input_cursor_pos;
            } else
                cursor_pos = text.get_length ();
        }
        if (text.get_length () > 0) {
            text.append_attribute (
                IBus.AttrType.UNDERLINE,
                IBus.AttrUnderline.SINGLE,
                0,
                (int) text.get_length ());
        }

        if (context.has_output ()) {
            var output = context.poll_output ();
            var ctext = new IBus.Text.from_string (output);
            commit_text (ctext);
        }

        update_preedit_text (text,
                             cursor_pos,
                             text.get_length () > 0);
    }

    void update_candidates () {
        populate_lookup_table ();
        set_lookup_table_cursor_pos ();
    }

    void update_input_mode () {
        bool changed;

        // Update the menu item
        var iter = input_mode_props.map_iterator ();
        while (iter.next ()) {
            var input_mode = iter.get_key ();
            var prop = iter.get_value ();

            changed = false;
            if (input_mode == context.input_mode) {
                if (prop.get_state () == IBus.PropState.UNCHECKED) {
                    prop.set_state (IBus.PropState.CHECKED);
                    changed = true;
                }
            } else {
                if (prop.get_state () == IBus.PropState.CHECKED) {
                    prop.set_state (IBus.PropState.UNCHECKED);
                    changed = true;
                }
            }
            if (changed && properties_registered)
                update_property (prop);
        }

        // Update the menu
        changed = false;
        var symbol = new IBus.Text.from_string (
            input_mode_symbols.get (context.input_mode));
        var label = new IBus.Text.from_string (
            _("Input Mode (%s)").printf (symbol.text));
        if (input_mode_prop.get_symbol () != symbol) {
            input_mode_prop.set_symbol (symbol);
            changed = true;
        }
        if (input_mode_prop.get_label () != label) {
            input_mode_prop.set_label (label);
            changed = true;
        }
        if (changed && properties_registered)
            update_property (input_mode_prop);
    }

    static void reload_dictionaries () {
        KkcEngine.dictionaries.clear ();
        Variant? variant;

        variant = settings.get_value ("user-dictionary");
        if (variant != null) {
            try {
                KkcEngine.dictionaries.add (new Kkc.UserDictionary (
                    variant.get_string ()));
            } catch (Error e) {
                warning ("can't load user dictionary %s: %s",
                         variant.get_string (),
                         e.message);
            }
        }

        variant = settings.get_value ("system-dictionaries");
        assert (variant != null);
        string[] strv = variant.dup_strv ();
        foreach (var id in strv) {
            var metadata = registry.get_metadata (id);
            try {
                KkcEngine.dictionaries.add (
                    new Kkc.SystemSegmentDictionary (metadata.filename,
                                                     metadata.encoding));
            } catch (Error e) {
                warning ("can't load system dictionary %s: %s",
                         metadata.filename,
                         e.message);
            }
        }
    }

    void apply_settings () {
        settings.bind ("punctuation-style",
                       context,
                       "punctuation-style",
                       SettingsBindFlags.GET);
        settings.bind ("auto-correct",
                       context,
                       "auto-correct",
                       SettingsBindFlags.GET);
        settings.bind ("page-size",
                       context.candidates,
                       "page-size",
                       SettingsBindFlags.GET);
        settings.bind ("pagination-start",
                       context.candidates,
                       "page-start",
                       SettingsBindFlags.GET);
        settings.bind ("initial-input-mode",
                       context,
                       "input-mode",
                       SettingsBindFlags.GET);
        settings.bind_with_mapping ("typing-rule",
                                    context,
                                    "typing-rule",
                                    SettingsBindFlags.GET,
                                    (SettingsBindGetMappingShared)
                                        typing_rule_get_mapping,
                                    (v, t) => {
                                        assert_not_reached ();
                                    },
                                    null, null);

        lookup_table.set_page_size (settings.get_int ("page-size"));
        settings.changed["page-size"].connect ((key) => {
            lookup_table.set_page_size (settings.get_int ("page-size"));
        });
        show_annotation = settings.get_boolean ("show-annotation");
        settings.changed["show-annotation"].connect ((key) => {
            show_annotation = settings.get_boolean ("show-annotation");
        });
        use_custom_keymap = settings.get_boolean ("use-custom-keymap");
        settings.changed["use-custom-keymap"].connect ((key) => {
            use_custom_keymap = settings.get_boolean ("use-custom-keymap");
        });
        keymap = IBus.Keymap.get (settings.get_string ("keymap"));
        settings.changed["keymap"].connect ((key) => {
            keymap = IBus.Keymap.get (settings.get_string ("keymap"));
        });
    }

    static bool typing_rule_get_mapping (Value value,
                                         Variant variant) {
        var parent_metadata = Kkc.RuleMetadata.find (variant.get_string ());
        assert (parent_metadata != null);

        var base_dir = Path.build_filename (
            Environment.get_user_config_dir (),
            "ibus-kkc", "rules");

        try {
            value.set_object (new Kkc.UserRule (parent_metadata,
                                                base_dir,
                                                "ibus-kkc"));
        } catch (Error e) {
            warning ("can't load typing rule %s: %s",
                     variant.get_string (), e.message);
        }
        return true;
    }

    IBus.Property register_input_mode_property (Kkc.InputMode mode,
                                                string name,
                                                string label,
                                                string symbol)
    {
        var prop = new IBus.Property (name,
                                      IBus.PropType.RADIO,
                                      new IBus.Text.from_string (label),
                                      null,
                                      null,
                                      true,
                                      true,
                                      IBus.PropState.UNCHECKED,
                                      null);
        input_mode_props.set (mode, prop);
        input_mode_symbols.set (mode, symbol);
        name_input_modes.set (name, mode);
        return prop;
    }

    static const string[] LOOKUP_TABLE_LABELS = {
        "1", "2", "3", "4", "5", "6", "7", "8",
        "9", "0", "a", "b", "c", "d", "e", "f"
    };

    bool process_lookup_table_key_event (uint keyval,
                                         uint keycode,
                                         uint state)
    {
        var page_size = lookup_table.get_page_size ();
        if (state == 0 &&
            ((unichar) keyval).to_string () in LOOKUP_TABLE_LABELS) {
            string label = ((unichar) keyval).tolower ().to_string ();
            for (var index = 0;
                 index < int.min ((int)page_size, LOOKUP_TABLE_LABELS.length);
                 index++) {
                if (LOOKUP_TABLE_LABELS[index] == label) {
                    return context.candidates.select_at (index);
                }
            }
            return false;
        }

        if (state == 0) {
            bool retval = false;
            switch (keyval) {
            case IBus.Page_Up:
            case IBus.KP_Page_Up:
                retval = context.candidates.page_up ();
                break;
            case IBus.Page_Down:
            case IBus.KP_Page_Down:
                retval = context.candidates.page_down ();
                break;
            case IBus.Up:
                retval = context.candidates.cursor_up ();
                break;
            case IBus.Down:
                retval = context.candidates.cursor_down ();
                break;
            default:
                return false;
            }

            if (retval) {
                set_lookup_table_cursor_pos ();
                update_preedit ();
            }
            return true;
        }

        return false;
    }

    public override bool process_key_event (uint keyval,
                                            uint keycode,
                                            uint state)
    {
        uint _keyval = keyval;

        if (use_custom_keymap)
            _keyval = keymap.lookup_keysym ((uint16) keycode, (uint32) state);

        // Filter out unnecessary modifier bits
        // FIXME: should resolve virtual modifiers
        uint _state = state & (IBus.ModifierType.SHIFT_MASK |
                               IBus.ModifierType.CONTROL_MASK |
                               IBus.ModifierType.MOD1_MASK |
                               IBus.ModifierType.MOD5_MASK |
                               IBus.ModifierType.RELEASE_MASK);
        if (context.candidates.page_visible &&
            process_lookup_table_key_event (_keyval, keycode, _state)) {
            return true;
        }

        var key = new Kkc.KeyEvent.from_x_event (_keyval,
                                                 keycode,
                                                 (Kkc.ModifierType) _state);

        var retval = context.process_key_event (key);

        // Hack for the direct input mode: if the keyval is translated
        // in the custom keymap and the new keyval is printable, send
        // it as a text event.
        if (!retval && use_custom_keymap &&
            _keyval != keyval &&
            0x20 <= _keyval && _keyval <= 0x7F &&
            (state & IBus.ModifierType.RELEASE_MASK) == 0) {
            var builder = new StringBuilder ();
            builder.append_c ((char) _keyval);
            var text = new IBus.Text.from_string (builder.str);
            commit_text (text);
            return true;
        }

        return retval;
    }

    uint save_dictionaries_timeout_id = 0;

    public override void enable () {
        context.reset ();

        save_dictionaries_timeout_id = Timeout.add_seconds_full (
            Priority.LOW,
            300,
            () => {
                context.dictionaries.save ();
                return true;
            });

        base.enable ();
    }

    public override void disable () {
        focus_out ();

        if (save_dictionaries_timeout_id > 0) {
            Source.remove (save_dictionaries_timeout_id);
            save_dictionaries_timeout_id = 0;
        }
        context.dictionaries.save ();

        base.disable ();
    }

    public override void reset () {
        context.reset ();
        var empty_text = new IBus.Text.from_static_string ("");
        update_preedit_text (empty_text,
                             0,
                             false);
        base.reset ();
    }

    public override void focus_in () {
        update_input_mode ();
        register_properties (prop_list);
        properties_registered = true;
        base.focus_in ();
    }

    public override void focus_out () {
        context.reset ();
        hide_preedit_text ();
        hide_lookup_table ();
        properties_registered = false;
        base.focus_out ();
    }

    public override void property_activate (string prop_name,
                                            uint prop_state)
    {
        if (prop_name == "setup") {
            var filename = Path.build_filename (Config.LIBEXECDIR,
                                                "ibus-setup-kkc");
            try {
                Process.spawn_command_line_async (filename);
            } catch (GLib.SpawnError e) {
                warning ("can't spawn %s: %s", filename, e.message);
            }
        }
        else if (prop_name.has_prefix ("InputMode.") &&
                 prop_state == IBus.PropState.CHECKED) {
            context.input_mode = name_input_modes.get (prop_name);
        }
    }

    public override void candidate_clicked (uint index, uint button, uint state) {
        context.candidates.select_at (index);
    }

    public override void cursor_up () {
        context.candidates.cursor_up ();
    }

    public override void cursor_down () {
        context.candidates.cursor_down ();
    }

    public override void page_up () {
        context.candidates.page_up ();
    }

    public override void page_down () {
        context.candidates.page_down ();
    }

    static bool ibus;

    const OptionEntry[] options = {
        {"ibus", 'i', 0, OptionArg.NONE, ref ibus,
         N_("Component is executed by IBus"), null },
        { null }
    };

    public static int main (string[] args) {
        IBus.init ();
        Kkc.init ();
        Gtk.init (ref args);

        Intl.bindtextdomain (Config.GETTEXT_PACKAGE, Config.LOCALEDIR);
        Intl.bind_textdomain_codeset (Config.GETTEXT_PACKAGE, "UTF-8");
        Intl.textdomain (Config.GETTEXT_PACKAGE);

        var context = new OptionContext ("- ibus kkc");
        context.add_main_entries (options, "ibus-kkc");
        try {
            context.parse (ref args);
        } catch (OptionError e) {
            stderr.printf ("%s\n", e.message);
            return 1;
        }

        var bus = new IBus.Bus ();
        if (!bus.is_connected ()) {
            stderr.printf ("cannot connect to ibus-daemon!\n");
            return 1;
        }

        bus.disconnected.connect (() => { IBus.quit (); });

        try {
            KkcEngine.language_model = Kkc.LanguageModel.load ("sorted3");
        } catch (Error e) {
            stderr.printf ("can't load language model: %s\n", e.message);
            return 1;
        }

        KkcEngine.settings = new Settings ("org.freedesktop.ibus.engine.kkc");
        KkcEngine.registry = new DictionaryRegistry ();
        KkcEngine.dictionaries = new ArrayList<Kkc.Dictionary> ();

        // KkcEngine.settings.bind() requires an instance instead of KkcEngine.
        KkcEngine.reload_dictionaries ();
        KkcEngine.settings.changed["dictionaries"].connect ((key) => {
                KkcEngine.reload_dictionaries ();
            });

        var factory = new IBus.Factory (bus.get_connection());
        factory.add_engine ("kkc", typeof(KkcEngine));
        if (ibus) {
            bus.request_name ("org.freedesktop.IBus.KKC", 0);
        } else {
            var component = new IBus.Component (
                "org.freedesktop.IBus.KKC",
                N_("Kana Kanji"), Config.PACKAGE_VERSION, "GPL",
                "Daiki Ueno <ueno@gnu.org>",
                "https://github.com/ueno/ibus-kkc",
                "",
                "ibus-kkc");
            var engine = new IBus.EngineDesc (
                "kkc",
                "Kana Kanji",
                "Kana Kanji Input Method",
                "ja",
                "GPL",
                "Daiki Ueno <ueno@gnu.org>",
                "%s/icons/ibus-kkc.svg".printf (Config.PACKAGE_DATADIR),
                "us");
            component.add_engine (engine);
            bus.register_component (component);
        }
        IBus.main ();
        return 0;
    }
}
