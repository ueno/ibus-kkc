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

struct SettingsBindData {
    Gtk.ComboBox combo;
    int column;
    unowned EnumClass eclass;
}

class DictionaryCellRenderer : Gtk.CellRendererText {
    private DictionaryMetadata _metadata;
    public DictionaryMetadata metadata {
        get {
            return _metadata;
        }
        set {
            _metadata = value;
            text = dgettext (null, _metadata.name);
        }
    }
}

[GtkTemplate (ui = "/org/freedesktop/ibus/engine/kkc/dictionary-dialog.ui")]
class DictionaryDialog : Gtk.Dialog {
    [GtkChild]
    Gtk.TreeView available_dictionaries_treeview;

    Settings settings;

    public DictionaryDialog (Settings settings) {
        this.settings = settings;

        Gtk.ListStore model;
        Gtk.CellRenderer renderer;
        Gtk.TreeViewColumn column;

        model = new Gtk.ListStore (2,
                                   typeof (DictionaryMetadata),
                                   typeof (string));
        available_dictionaries_treeview.set_model (model);

        renderer = new DictionaryCellRenderer ();
        column = new Gtk.TreeViewColumn.with_attributes ("dict", renderer,
                                                         "metadata", 0);
        available_dictionaries_treeview.append_column (column);
        settings.bind_with_mapping ("system-dictionaries",
                                    available_dictionaries_treeview,
                                    "model",
                                    SettingsBindFlags.GET,
                                    (SettingsBindGetMappingShared)
                                        treeview_available_dict_get_mapping,
                                    (v, t) => {
                                        assert_not_reached ();
                                    },
                                    null, null);
    }        

    static bool treeview_available_dict_get_mapping (Value value,
                                                     Variant variant) {
        var _variant = variant;
        if (_variant.equal (new Variant.strv ({})))
            _variant =  SetupDialog.get_system_dictionaries ();
        assert (_variant != null);
        var strv = _variant.dup_strv ();

        Set<string> enabled = new Gee.HashSet<string> ();
        foreach (var str in strv) {
            enabled.add (str);
        }

        var model = new Gtk.ListStore (2,
                                       typeof (DictionaryMetadata),
                                       typeof (string));
        var available_dictionaries = SetupDialog.list_available_dictionaries ();
        foreach (var metadata in available_dictionaries) {
            if (!enabled.contains (metadata.id)) {
                Gtk.TreeIter iter;
                model.append (out iter);
                model.set (iter,
                           0, metadata,
                           1, dgettext (null, metadata.description));
            }
        }
        value.set_object (model);
        return true;
    }

    public DictionaryMetadata[] get_dictionaries () {
        DictionaryMetadata[] dictionaries = {};
        var selection = available_dictionaries_treeview.get_selection ();
        Gtk.TreeModel available_model;
        var rows = selection.get_selected_rows (out available_model);
        foreach (var row in rows) {
            Gtk.TreeIter available_iter;
            if (available_model.get_iter (out available_iter, row)) {
                DictionaryMetadata metadata;
                available_model.get (available_iter, 0, out metadata, -1);
                dictionaries += metadata;
            }
        }
        return dictionaries;
    }
}

[GtkTemplate (ui = "/org/freedesktop/ibus/engine/kkc/shortcut-dialog.ui")]
class ShortcutDialog : Gtk.Dialog {
    [GtkChild]
    Gtk.ComboBox shortcut_command_combobox;

    public ShortcutDialog () {
        Gtk.ListStore model;
        Gtk.CellRenderer renderer;

        model = new Gtk.ListStore (2, typeof (string), typeof (string));
        model.set_sort_column_id (1, Gtk.SortType.ASCENDING);
        shortcut_command_combobox.set_model (model);
        var commands = Kkc.Keymap.commands ();
        foreach (var command in commands) {
            Gtk.TreeIter iter;
            model.append (out iter);
            model.set (iter,
                       0, command,
                       1, Kkc.Keymap.get_command_label (command));
        }
        shortcut_command_combobox.set_active (0);

        renderer = new Gtk.CellRendererText ();
        shortcut_command_combobox.pack_start (renderer, false);
        shortcut_command_combobox.set_attributes (renderer, "text", 1);
    }

    string combobox_get_active_string (Gtk.ComboBox combo, int column) {
        string text;
        Gtk.TreeIter iter;
        if (combo.get_active_iter (out iter)) {
            var model = (Gtk.ListStore) combo.get_model ();
            model.get (iter, column, out text, -1);
        } else {
            assert_not_reached ();
        }
        return text;
    }

    public string get_command () {
        return combobox_get_active_string (shortcut_command_combobox, 0);
    }
}

[GtkTemplate (ui = "/org/freedesktop/ibus/engine/kkc/setup-dialog.ui")]
class SetupDialog : Gtk.Dialog {
    [GtkChild]
    Gtk.TreeView dictionaries_treeview;
    [GtkChild]
    Gtk.ComboBox punctuation_style_combobox;
    [GtkChild]
    Gtk.CheckButton auto_correct_checkbutton;
    [GtkChild]
    Gtk.CheckButton use_custom_keymap_checkbutton;
    [GtkChild]
    Gtk.ComboBox keymap_combobox;
    [GtkChild]
    Gtk.SpinButton page_size_spinbutton;
    [GtkChild]
    Gtk.SpinButton pagination_start_spinbutton;
    [GtkChild]
    Gtk.CheckButton show_annotation_checkbutton;
    [GtkChild]
    Gtk.ComboBox initial_input_mode_combobox;
    [GtkChild]
    Gtk.ComboBox typing_rule_combobox;
    [GtkChild]
    Gtk.TreeView input_mode_treeview;
    [GtkChild]
    Gtk.ToolButton add_dict_toolbutton;
    [GtkChild]
    Gtk.ToolButton remove_dict_toolbutton;
    [GtkChild]
    Gtk.ToolButton up_dict_toolbutton;
    [GtkChild]
    Gtk.ToolButton down_dict_toolbutton;
    [GtkChild]
    Gtk.TreeView shortcut_treeview;
    [GtkChild]
    Gtk.ToolButton add_shortcut_toolbutton;
    [GtkChild]
    Gtk.ToolButton remove_shortcut_toolbutton;
    [GtkChild]
    Gtk.Label version_label;

    Settings settings;
    static DictionaryRegistry registry;

    Kkc.UserRule shortcut_rule;
    Kkc.InputMode shortcut_input_mode;

    public SetupDialog () {
        version_label.use_markup = true;
        version_label.label = "<b>%s</b>".printf (Config.VERSION);

        settings = new Settings ("org.freedesktop.ibus.engine.kkc");
        registry = new DictionaryRegistry ();

        page_size_spinbutton.set_range (7.0, 16.0);
        page_size_spinbutton.set_increments (1.0, 1.0);

        pagination_start_spinbutton.set_range (0.0, 7.0);
        pagination_start_spinbutton.set_increments (1.0, 1.0);

        Gtk.ListStore model;
        Gtk.CellRenderer renderer;
        Gtk.TreeViewColumn column;

        model = new Gtk.ListStore (2,
                                   typeof (DictionaryMetadata),
                                   typeof (string));
        dictionaries_treeview.set_model (model);

        renderer = new DictionaryCellRenderer ();
        column = new Gtk.TreeViewColumn.with_attributes ("dict", renderer,
                                                         "metadata", 0);
        dictionaries_treeview.append_column (column);

        renderer = new Gtk.CellRendererText ();
        punctuation_style_combobox.pack_start (renderer, false);
        punctuation_style_combobox.set_attributes (renderer, "text", 0);

        renderer = new Gtk.CellRendererText ();
        initial_input_mode_combobox.pack_start (renderer, false);
        initial_input_mode_combobox.set_attributes (renderer, "text", 0);

        renderer = new Gtk.CellRendererText ();
        column = new Gtk.TreeViewColumn.with_attributes ("Mode",
                                                         renderer,
                                                         "text", 0);
        input_mode_treeview.append_column (column);
        var input_mode_selection = input_mode_treeview.get_selection ();
        input_mode_selection.changed.connect (() => {
                Gtk.TreeIter iter;
                Gtk.TreeModel _model;
                if (input_mode_selection.get_selected (out _model, out iter)) {
                    int input_mode;
                    _model.get (iter, 1, out input_mode, -1);
                    populate_shortcut_treeview ((Kkc.InputMode) input_mode);
                }
            });

        model = new Gtk.ListStore (3,
                                   typeof (string),
                                   typeof (Kkc.KeyEvent),
                                   typeof (string));
        model.set_sort_column_id (0, Gtk.SortType.ASCENDING);
        shortcut_treeview.set_model (model);
        renderer = new Gtk.CellRendererText ();
        column = new Gtk.TreeViewColumn.with_attributes ("Command",
                                                         renderer,
                                                         "text", 2);
        shortcut_treeview.append_column (column);

        var accel_renderer = new KeyEventCellRenderer ();
        accel_renderer.set ("editable", true,
                            "accel-mode", Gtk.CellRendererAccelMode.OTHER,
                            null);
        column = new Gtk.TreeViewColumn.with_attributes ("Shortcut",
                                                         accel_renderer,
                                                         "event", 1);
        shortcut_treeview.append_column (column);

        accel_renderer.accel_edited.connect (accel_edited);
        accel_renderer.accel_cleared.connect (accel_cleared);

        var shortcut_selection = shortcut_treeview.get_selection ();
        shortcut_selection.changed.connect (() => {
                int count = shortcut_selection.count_selected_rows ();
                if (count > 0) {
                    remove_shortcut_toolbutton.sensitive = true;
                } else if (count == 0) {
                    remove_shortcut_toolbutton.sensitive = false;
                }
            });

        add_shortcut_toolbutton.clicked.connect (add_shortcut);
        remove_shortcut_toolbutton.clicked.connect (remove_shortcut);

        model = new Gtk.ListStore (2, typeof (string), typeof (string));
        model.set_sort_column_id (1, Gtk.SortType.ASCENDING);
        typing_rule_combobox.set_model (model);

        var rules = Kkc.Rule.list ();
        foreach (var rule in rules) {
            if (rule.priority > 70) {
                Gtk.TreeIter iter;
                model.append (out iter);
                model.set (iter, 0, rule.name, 1, rule.label);
            }
        }

        renderer = new Gtk.CellRendererText ();
        typing_rule_combobox.pack_start (renderer, false);
        typing_rule_combobox.set_attributes (renderer, "text", 1);

        renderer = new Gtk.CellRendererText ();
        keymap_combobox.pack_start (renderer, false);
        keymap_combobox.set_attributes (renderer, "text", 1);

        load ();

        add_dict_toolbutton.clicked.connect (add_dict);
        remove_dict_toolbutton.clicked.connect (remove_dict);
        up_dict_toolbutton.clicked.connect (up_dict);
        down_dict_toolbutton.clicked.connect (down_dict);

        var dictionaries_selection = dictionaries_treeview.get_selection ();
        dictionaries_selection.changed.connect (() => {
                int count = dictionaries_selection.count_selected_rows ();
                if (count > 0) {
                    remove_dict_toolbutton.sensitive = true;

                    Gtk.TreeModel _model;
                    Gtk.TreeIter iter;
                    if (dictionaries_selection.get_selected (out _model,
                                                             out iter)) {
                        Gtk.TreeIter prev = iter;
                        up_dict_toolbutton.sensitive =
                            _model.iter_previous (ref prev);

                        Gtk.TreeIter next = iter;
                        down_dict_toolbutton.sensitive =
                            _model.iter_next (ref next);
                    }
                } else if (count == 0) {
                    remove_dict_toolbutton.sensitive = false;
                    up_dict_toolbutton.sensitive = false;
                    down_dict_toolbutton.sensitive = false;
                }
            });
    }

    void accel_edited (string path_string,
                       uint keyval,
                       Gdk.ModifierType modifiers,
                       uint keycode)
    {
        Gtk.TreeIter iter;
        var model = (Gtk.ListStore) shortcut_treeview.get_model ();
        if (model.get_iter_from_string (out iter, path_string)) {
            Kkc.KeyEvent new_event = new Kkc.KeyEvent.from_x_event (
                keyval,
                keycode,
                (Kkc.ModifierType) modifiers);
            var keymap = shortcut_rule.get_keymap (shortcut_input_mode);
            var old_command = keymap.lookup_key (new_event);
            if (old_command != null) {
                string new_command;
                model.get (iter,
                           0, out new_command,
                           -1);
                if (old_command != new_command) {
                    var error_dialog = new Gtk.MessageDialog (
                        this,
                        Gtk.DialogFlags.MODAL,
                        Gtk.MessageType.ERROR,
                        Gtk.ButtonsType.CLOSE,
                        _("Shortcut '%s' is already assigned to '%s'"),
                        new_event.to_string (),
                        old_command);
                    error_dialog.run ();
                    error_dialog.destroy ();
                }
            } else {
                string new_command;
                Kkc.KeyEvent *old_event;
                model.get (iter,
                           0, out new_command,
                           1, out old_event,
                           -1);
                if (old_event != null)
                    keymap.set (old_event, null);
                keymap.set (new_event, new_command);
                try {
                    shortcut_rule.write (shortcut_input_mode);
                } catch (Error e) {
                    warning ("can't write shortcut: %s", e.message);
                }
                model.set (iter, 1, new_event, -1);

                // Notify engine that the typing rule has been modified.
                typing_rule_combobox.changed ();
            }
        }
    }

    void accel_cleared (string path_string) {
        Gtk.TreeIter iter;
        var model = (Gtk.ListStore) shortcut_treeview.get_model ();
        if (model.get_iter_from_string (out iter, path_string)) {
            Kkc.KeyEvent *old_event;
            model.get (iter, 1, out old_event, -1);
            var keymap = shortcut_rule.get_keymap (shortcut_input_mode);
            if (old_event != null)
                keymap.set (old_event, null);
            try {
                shortcut_rule.write (shortcut_input_mode);
            } catch (Error e) {
                warning ("can't write shortcut: %s", e.message);
            }
#if VALA_0_36
            model.remove (ref iter);
#else
            model.remove (iter);
#endif
        }
    }

    void add_shortcut () {
        var shortcut_dialog = new ShortcutDialog ();
        shortcut_dialog.set_transient_for (this);
        if (shortcut_dialog.run () == Gtk.ResponseType.OK) {
            var command = shortcut_dialog.get_command ();
            Gtk.TreeIter iter;
            var model = (Gtk.ListStore) shortcut_treeview.get_model ();
            model.append (out iter);
            model.set (iter,
                       0, command,
                       1, null,
                       2, Kkc.Keymap.get_command_label (command),
                       -1);
        }
        shortcut_dialog.hide ();
    }

    void remove_shortcut () {
        var selection = shortcut_treeview.get_selection ();
        Gtk.TreeModel model;
        var rows = selection.get_selected_rows (out model);
        var keymap = shortcut_rule.get_keymap (shortcut_input_mode);
        foreach (var row in rows) {
            Gtk.TreeIter iter;
            if (model.get_iter (out iter, row)) {
                Kkc.KeyEvent *old_event;
                model.get (iter, 1, out old_event, -1);
                if (old_event != null) {
                    if (old_event->modifiers == 0 &&
                        old_event->keyval in IGNORED_KEYVALS)
                        continue;
                    keymap.set (old_event, null);
                }
#if VALA_0_36
                ((Gtk.ListStore)model).remove (ref iter);
#else
                ((Gtk.ListStore)model).remove (iter);
#endif
            }
        }
        try {
            shortcut_rule.write (shortcut_input_mode);
        } catch (Error e) {
            warning ("can't write shortcut: %s", e.message);
        }
    }

    void populate_shortcut_treeview (Kkc.InputMode input_mode) {
        var variant = settings.get_value ("typing-rule");
        assert (variant != null);

        var parent_metadata = Kkc.RuleMetadata.find (variant.get_string ());
        assert (parent_metadata != null);

        var base_dir = Path.build_filename (
            Environment.get_user_config_dir (),
            "ibus-kkc", "rules");

        Kkc.UserRule rule;
        try {
            rule = new Kkc.UserRule (parent_metadata, base_dir, "ibus-kkc");
        } catch (Error e) {
            error ("can't load typing rule %s: %s",
                   variant.get_string (), e.message);
        }

        var model = (Gtk.ListStore) shortcut_treeview.get_model ();
        model.clear ();
        var entries = rule.get_keymap (input_mode).entries ();
        foreach (var entry in entries) {
            if (entry.command != null) {
                Gtk.TreeIter iter;
                model.append (out iter);
                model.set (iter,
                           0, entry.command,
                           1, entry.key,
                           2, Kkc.Keymap.get_command_label (entry.command));
            }
        }
        shortcut_input_mode = input_mode;
        shortcut_rule = rule;
    }

    void add_dict () {
        var dictionary_dialog = new DictionaryDialog (settings);
        dictionary_dialog.set_transient_for (this);
        if (dictionary_dialog.run () == Gtk.ResponseType.OK) {
            var dictionaries = dictionary_dialog.get_dictionaries ();
            var model = (Gtk.ListStore) dictionaries_treeview.get_model ();
            foreach (var dictionary in dictionaries) {
                Gtk.TreeIter iter;
                model.append (out iter);
                model.set (iter, 0, dictionary);
            }
            dictionaries_treeview.set ("model", model);
        }
        dictionary_dialog.hide ();
    }

    void remove_dict () {
        var selection = dictionaries_treeview.get_selection ();
        Gtk.TreeModel model;
        var rows = selection.get_selected_rows (out model);
        foreach (var row in rows) {
            Gtk.TreeIter iter;
            if (model.get_iter (out iter, row)) {
#if VALA_0_36
                ((Gtk.ListStore)model).remove (ref iter);
#else
                ((Gtk.ListStore)model).remove (iter);
#endif
            }
        }
        dictionaries_treeview.set ("model", model);
    }

    void up_dict () {
        var selection = dictionaries_treeview.get_selection ();
        Gtk.TreeModel model;
        Gtk.TreeIter iter;
        if (selection.get_selected (out model, out iter)) {
            Gtk.TreeIter prev = iter;
            if (model.iter_previous (ref prev)) {
                ((Gtk.ListStore)model).swap (iter, prev);
                down_dict_toolbutton.sensitive = true;
                prev = iter;
                up_dict_toolbutton.sensitive = model.iter_previous (ref prev);
            }
        }
        dictionaries_treeview.set ("model", model);
    }

    void down_dict () {
        var selection = dictionaries_treeview.get_selection ();
        Gtk.TreeModel model;
        Gtk.TreeIter iter;
        if (selection.get_selected (out model, out iter)) {
            Gtk.TreeIter next = iter;
            if (model.iter_next (ref next)) {
                ((Gtk.ListStore)model).swap (iter, next);
                up_dict_toolbutton.sensitive = true;
                next = iter;
                down_dict_toolbutton.sensitive = model.iter_next (ref next);
            }
        }
        dictionaries_treeview.set ("model", model);
    }

    static bool combobox_enum_get_mapping (Value value,
                                           Variant variant,
                                           SettingsBindData data) {
        var combo = data.combo;
        int column = data.column;
        unowned EnumClass eclass = data.eclass;
        string nick = variant.get_string(null);
        var evalue = eclass.get_value_by_nick (nick);
        int mode = evalue.value;
        int index = 0;
        var model = combo.get_model ();
        Gtk.TreeIter iter;
        if (model.get_iter_first (out iter)) {
            do {
                int _mode;
                model.get (iter, column, out _mode, -1);
                if (mode == _mode) {
                    value.set_int(index);
                    return true;
                }
                index++;
            } while (model.iter_next (ref iter));
        }
        assert_not_reached ();
    }

    static Variant combobox_enum_set_mapping (Value value,
                                              VariantType expected_type,
                                              SettingsBindData data) {
        var combo = data.combo;
        int column = data.column;
        unowned EnumClass eclass = data.eclass;
        Gtk.TreeIter iter;
        if (combo.get_active_iter (out iter)) {
            int mode;
            var model = combo.get_model ();
            model.get (iter, column, out mode, -1);
            var evalue = eclass.get_value (mode);
            return evalue.value_nick;
        }
        assert_not_reached ();
    }

    static bool treeview_dict_get_mapping (Value value,
                                           Variant variant) {
        var _variant = variant;
        if (_variant.equal (new Variant.strv ({})))
            _variant =  get_system_dictionaries ();
        assert (_variant != null);
        var strv = _variant.dup_strv ();

        var model = new Gtk.ListStore (2,
                                       typeof (DictionaryMetadata),
                                       typeof (string));
        foreach (var id in strv) {
            var metadata = registry.get_metadata (id);
            if (metadata != null) {
                Gtk.TreeIter iter;
                model.append (out iter);
                model.set (iter,
                           0, metadata,
                           1, dgettext (null, metadata.description));
            }
        }
        value.set_object (model);
        return true;
    }

    static Variant treeview_dict_set_mapping (Value value,
                                              VariantType expected_type) {
        var model = value.get_object () as Gtk.TreeModel;
        Gtk.TreeIter iter;
        ArrayList<string> dictionaries = new ArrayList<string> ();
        if (model.get_iter_first (out iter)) {
            do {
                DictionaryMetadata metadata;
                model.get (iter, 0, out metadata, -1);
                dictionaries.add (metadata.id);
            } while (model.iter_next (ref iter));
        }
        return dictionaries.to_array ();
    }

    void settings_combobox_string (string name,
                                   Gtk.ComboBox combo,
                                   int column) {
        combo.set_id_column (column);
        settings.bind (name, combo, "active-id", SettingsBindFlags.DEFAULT);
    }

    void settings_combobox_enum (string name,
                                 Gtk.ComboBox combo,
                                 int column,
                                 EnumClass eclass) {
        SettingsBindData *data = malloc (sizeof (SettingsBindData));
        *data = SettingsBindData() {
            combo = combo, column = column, eclass = eclass
        };
        settings.bind_with_mapping (name,
                                    combo,
                                    "active",
                                    SettingsBindFlags.DEFAULT,
                                    (SettingsBindGetMappingShared)
                                        combobox_enum_get_mapping,
                                    (SettingsBindSetMappingShared)
                                        combobox_enum_set_mapping,
                                    data, free);
    }

    void settings_treeview_dict (string name,
                                 Gtk.TreeView treeview) {
        settings.bind_with_mapping (name,
                                    treeview,
                                    "model",
                                    SettingsBindFlags.DEFAULT,
                                    (SettingsBindGetMappingShared)
                                        treeview_dict_get_mapping,
                                    (SettingsBindSetMappingShared)
                                        treeview_dict_set_mapping,
                                    null, null);
    }

    void select_shortcut_section (Kkc.InputMode input_mode) {
        Gtk.TreeIter iter;
        var model = input_mode_treeview.get_model ();
        if (model.get_iter_first (out iter)) {
            do {
                int _input_mode;
                model.get (iter, 1, out _input_mode, -1);
                if (_input_mode == input_mode) {
                    var selection = input_mode_treeview.get_selection ();
                    selection.select_iter (iter);
                    break;
                }
            } while (model.iter_next (ref iter));
        }
    }

    void load () {
        settings_combobox_string ("typing-rule", typing_rule_combobox, 0);
        settings_combobox_enum (
            "initial-input-mode",
            initial_input_mode_combobox,
            1,
            (EnumClass)typeof (Kkc.InputMode).class_ref ());
        settings_combobox_enum (
            "punctuation-style",
            punctuation_style_combobox,
            1,
            (EnumClass)typeof (Kkc.PunctuationStyle).class_ref ());
        settings.bind ("auto-correct",
                       auto_correct_checkbutton,
                       "active",
                       SettingsBindFlags.DEFAULT);
        settings.bind ("use-custom-keymap",
                       use_custom_keymap_checkbutton,
                       "active",
                       SettingsBindFlags.DEFAULT);
        settings_combobox_string ("keymap", keymap_combobox, 0);
        settings.bind ("use-custom-keymap",
                       keymap_combobox,
                       "sensitive",
                       SettingsBindFlags.GET);

        settings.bind ("page-size",
                       page_size_spinbutton,
                       "value",
                       SettingsBindFlags.DEFAULT);
        settings.bind ("pagination-start",
                       pagination_start_spinbutton,
                       "value",
                       SettingsBindFlags.DEFAULT);
        settings.bind ("show-annotation",
                       show_annotation_checkbutton,
                       "active",
                       SettingsBindFlags.DEFAULT);

        settings_treeview_dict ("system-dictionaries", dictionaries_treeview);
        select_shortcut_section (Kkc.InputMode.HIRAGANA);
    }

    static const uint[] IGNORED_KEYVALS = {
        Kkc.Keysyms.BackSpace,
        Kkc.Keysyms.Escape
    };

    class KeyEventCellRenderer : Gtk.CellRendererAccel {
        private Kkc.KeyEvent _event;
        public Kkc.KeyEvent event {
            get {
                return _event;
            }
            set {
                accel_mode = Gtk.CellRendererAccelMode.OTHER;
                _event = value;
                if (_event == null) {
                    accel_key = 0;
                    accel_mods = 0;
                    keycode = 0;
                } else {
                    accel_key = _event.keyval;
                    accel_mods = (Gdk.ModifierType) _event.modifiers;
                    keycode = _event.keycode;
                }
                if (accel_mods == 0 && accel_key in IGNORED_KEYVALS)
                    editable = false;
                else
                    editable = true;
            }
        }
    }

    public static DictionaryMetadata[] list_available_dictionaries () {
        return registry.list_available ();
    }

    public static Variant get_system_dictionaries () {
        ArrayList<string> dictionaries = new ArrayList<string> ();
        foreach (var metadata in list_available_dictionaries ()) {
            if (metadata.default_enabled) {
                dictionaries.add (metadata.id);
            }
        }
        return dictionaries.to_array ();
    }

    public static int main (string[] args) {
        IBus.init ();
        Kkc.init ();
        Gtk.init (ref args);

        Intl.bindtextdomain (Config.GETTEXT_PACKAGE, Config.LOCALEDIR);
        Intl.bind_textdomain_codeset (Config.GETTEXT_PACKAGE, "UTF-8");
        Intl.textdomain (Config.GETTEXT_PACKAGE);

        var bus = new IBus.Bus ();
        if (!bus.is_connected ()) {
            stderr.printf ("cannot connect to ibus-daemon!\n");
            return 1;
        }

        var setup_dialog = new SetupDialog ();

        setup_dialog.run ();
        return 0;
    }
}
