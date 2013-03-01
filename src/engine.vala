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

class KkcEngine : IBus.Engine {
    // Preferences are shared among KkcEngine instances.
    static Preferences preferences;

    // Dictionaries are shared among SkkEngine instances and
    // maintained in the per-class signal handler in main().
    static ArrayList<Kkc.Dictionary> dictionaries;

    Kkc.Context context;
    IBus.LookupTable lookup_table;
    uint page_start;
    bool lookup_table_visible;

    bool show_annotation;

    IBus.Property input_mode_prop;
    IBus.PropList prop_list;

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
            new IBus.Text.from_string (_("Setup")),
            "gtk-preferences",
            new IBus.Text.from_string (_("Configure KKC")),
            true,
            true,
            IBus.PropState.UNCHECKED,
            null);
        prop_list.append (prop);

        // Initialize libkkc
        Kkc.LanguageModel model;
        try {
            model = Kkc.LanguageModel.load ("sorted3");
        } catch (Kkc.LanguageModelError e) {
            warning ("can't load language model: %s\n", e.message);
        }

        context = new Kkc.Context (model);

        foreach (var dictionary in dictionaries) {
            context.dictionaries.add (dictionary);
        }

        apply_preferences ();
        preferences.value_changed.connect ((name, value) => {
                apply_preferences ();
                if (name == "dictionaries") {
                    // KkcEngine.dictionaries should be updated separately
                    context.dictionaries.clear ();
                    foreach (var dictionary in KkcEngine.dictionaries) {
                        context.dictionaries.add (dictionary);
                    }
                }
            });

        preferences.value_changed.connect ((name, value) => {
                apply_preferences ();
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
        for (int i = (int) page_start;
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
            if (show_annotation && candidate.annotation != null) {
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
        if (context.segments.cursor_pos >= 0) {
            text = new IBus.Text.from_string (context.segments.get_output ());
            int index = 0;
            int offset = 0;
            for (; index < context.segments.cursor_pos; index++) {
                offset += context.segments[index].output.char_count ();
            }
            text.append_attribute (
                IBus.AttrType.BACKGROUND,
                0x00aaaaaa,
                offset,
                offset + context.segments[index].output.char_count ());
            text.append_attribute (
                IBus.AttrType.FOREGROUND,
                0x00000000,
                offset,
                offset + context.segments[index].output.char_count ());
        } else {
            text = new IBus.Text.from_string (context.input);
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
                             text.get_length (),
                             text.get_length () > 0);
    }

    void update_candidates () {
        context.candidates.page_start = page_start;
        context.candidates.page_size = lookup_table.get_page_size ();
        populate_lookup_table ();
        set_lookup_table_cursor_pos ();
    }

    void update_input_mode () {
        // IBusProperty objects in input_mode_props are shared with
        // prop_list and will be used for the next
        // register_properties.  So, all the input mode props have to
        // be unchecked first.  Otherwise multiple radio items might
        // be selected.
        foreach (var prop in input_mode_props.values) {
            prop.set_state (IBus.PropState.UNCHECKED);
        }

        // Update the state of menu item
        var prop = input_mode_props.get (context.input_mode);
        prop.set_state (IBus.PropState.CHECKED);
        update_property (prop);
        
        // Update the label of the menu
        var symbol = new IBus.Text.from_string (
            input_mode_symbols.get (context.input_mode));
#if IBUS_1_5
        var label = new IBus.Text.from_string (
            _("Input Mode (%s)").printf (symbol.text));
        input_mode_prop.set_label (label);
        input_mode_prop.set_symbol (symbol);
#else
        input_mode_prop.set_label (symbol);
#endif
        update_property (input_mode_prop);
    }

    static Kkc.Dictionary? parse_dict_from_plist (PList plist) throws GLib.Error {
        var encoding = plist.get ("encoding") ?? "EUC-JP";
        var type = plist.get ("type");
        if (type == "file") {
            string? file = plist.get ("file");
            if (file == null) {
                return null;
            }
            string mode = plist.get ("mode") ?? "readonly";
            if (mode == "readonly") {
                return new Kkc.SystemSegmentDictionary (file, encoding);
            } else if (mode == "readwrite")
                return new Kkc.UserDictionary (file);
        }
        return null;
    }

    static void reload_dictionaries () {
        KkcEngine.dictionaries.clear ();
        Variant? variant = preferences.get ("dictionaries");
        assert (variant != null);
        string[] strv = variant.dup_strv ();
        foreach (var str in strv) {
            try {
                var plist = new PList (str);
                Kkc.Dictionary? dict = parse_dict_from_plist (plist);
                if (dict != null)
                    dictionaries.add (dict);
            } catch (PListParseError e) {
                warning ("can't parse plist \"%s\": %s",
                         str, e.message);
            } catch (GLib.Error e) {
                warning ("can't open dictionary \"%s\": %s",
                         str, e.message);
            }
        }
    }

    void apply_preferences () {
        Variant? variant;

        variant = preferences.get ("punctuation_style");
        assert (variant != null);
        context.punctuation_style = (Kkc.PunctuationStyle) variant.get_int32 ();

        variant = preferences.get ("page_size");
        assert (variant != null);
        lookup_table.set_page_size (variant.get_int32 ());

        variant = preferences.get ("pagination_start");
        assert (variant != null);
        page_start = (uint) variant.get_int32 ();

        variant = preferences.get ("initial_input_mode");
        assert (variant != null);
        context.input_mode = (Kkc.InputMode) variant.get_int32 ();

        variant = preferences.get ("show_annotation");
        assert (variant != null);
        show_annotation = variant.get_boolean ();
        
        variant = preferences.get ("typing_rule");
        assert (variant != null);
        try {
            context.typing_rule = new Kkc.Rule (variant.get_string ());
        } catch (Kkc.RuleParseError e) {
            warning ("can't load typing rule %s: %s",
                     variant.get_string (), e.message);
        }
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

    string[] LOOKUP_TABLE_LABELS = {"1", "2", "3", "4", "5", "6", "7",
                                    "8", "9", "0", "a", "b", "c", "d", "e"};

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
                break;
            }

            if (retval) {
                set_lookup_table_cursor_pos ();
                update_preedit ();
                return true;
            }
        }

        return false;
    }

    struct KeyEntry {
        uint keyval;
        uint modifiers;
    }

    // Keys should always be reported as handled (a8ffece4 and caf9f944)
    static const KeyEntry[] IGNORE_KEYS = {
        { IBus.j, IBus.ModifierType.CONTROL_MASK }
    };

    public override bool process_key_event (uint keyval,
                                            uint keycode,
                                            uint state)
    {
        // Filter out unnecessary modifier bits
        // FIXME: should resolve virtual modifiers
        uint _state = state & (IBus.ModifierType.SHIFT_MASK |
                               IBus.ModifierType.CONTROL_MASK |
                               IBus.ModifierType.MOD1_MASK |
                               IBus.ModifierType.MOD5_MASK |
                               IBus.ModifierType.RELEASE_MASK);
        if (context.candidates.page_visible &&
            process_lookup_table_key_event (keyval, keycode, _state)) {
            return true;
        }

        Kkc.ModifierType modifiers = (Kkc.ModifierType) _state;
        Kkc.KeyEvent key;
        try {
            key = new Kkc.KeyEvent.from_x_event (keyval, keycode, modifiers);
        } catch (Kkc.KeyEventFormatError e) {
            return false;
        }

        var retval = context.process_key_event (key);
        foreach (var entry in IGNORE_KEYS) {
            if (entry.keyval == keyval && entry.modifiers == modifiers) {
                return true;
            }
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
        register_properties (prop_list);
        update_input_mode ();
        base.focus_in ();
    }

    public override void focus_out () {
        context.reset ();
        hide_preedit_text ();
        hide_lookup_table ();
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

        Intl.setlocale (LocaleCategory.ALL, "");
        Intl.bindtextdomain (Config.GETTEXT_PACKAGE, Config.LOCALEDIR);
        Intl.bind_textdomain_codeset (Config.GETTEXT_PACKAGE, "UTF-8");

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

        var config = bus.get_config ();
        KkcEngine.preferences = new Preferences (config);
        KkcEngine.dictionaries = new ArrayList<Kkc.Dictionary> ();
        KkcEngine.reload_dictionaries ();
        KkcEngine.preferences.value_changed.connect ((name, value) => {
                if (name == "dictionaries") {
                    KkcEngine.reload_dictionaries ();
                }
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
                "http://code.google.com/p/ibus/",
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
