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

class Setup : Object {
    // main dialog
    Gtk.Dialog dialog;
    Gtk.TreeView dictionaries_treeview;
    Gtk.TreeView available_dictionaries_treeview;
    Gtk.ComboBox punctuation_style_combobox;
    Gtk.CheckButton auto_correct_checkbutton;
    Gtk.CheckButton use_custom_keymap_checkbutton;
    Gtk.ComboBox keymap_combobox;
    Gtk.SpinButton page_size_spinbutton;
    Gtk.SpinButton pagination_start_spinbutton;
    Gtk.CheckButton show_annotation_checkbutton;
    Gtk.ComboBox initial_input_mode_combobox;
    Gtk.ComboBox typing_rule_combobox;
    Gtk.TreeView input_mode_treeview;
    Gtk.TreeView shortcut_treeview;
    Gtk.ToolButton add_shortcut_toolbutton;
    Gtk.ToolButton remove_shortcut_toolbutton;

    // add dictionary dialog
    Gtk.Dialog dict_dialog;

    // shortcut dialog
    Gtk.Dialog shortcut_dialog;
    Gtk.ComboBox shortcut_command_combobox;

    Preferences preferences;

    Kkc.UserRule shortcut_rule;
    Kkc.InputMode shortcut_input_mode;

    public Setup (Preferences preferences) {
        this.preferences = preferences;

        var builder = new Gtk.Builder ();
        builder.set_translation_domain ("ibus-kkc");
        try {
            builder.add_from_resource (
                "/org/freedesktop/ibus/engine/kkc/preferences.ui");
        } catch (GLib.Error e) {
            error ("can't load ui from resource: %s", e.message);
        }

        // map widgets defined in ibus-kkc-preferences.ui
        Object? object;

        object = builder.get_object ("dialog");
        assert (object != null);
        dialog = (Gtk.Dialog) object;

        object = builder.get_object ("dictionaries_treeview");
        assert (object != null);
        dictionaries_treeview = (Gtk.TreeView) object;

        object = builder.get_object ("available_dictionaries_treeview");
        assert (object != null);
        available_dictionaries_treeview = (Gtk.TreeView) object;

        object = builder.get_object ("punctuation_style_combobox");
        assert (object != null);
        punctuation_style_combobox = (Gtk.ComboBox) object;

        object = builder.get_object ("auto_correct_checkbutton");
        assert (object != null);
        auto_correct_checkbutton = (Gtk.CheckButton) object;

        object = builder.get_object ("use_custom_keymap_checkbutton");
        assert (object != null);
        use_custom_keymap_checkbutton = (Gtk.CheckButton) object;

        object = builder.get_object ("keymap_combobox");
        assert (object != null);
        keymap_combobox = (Gtk.ComboBox) object;

        object = builder.get_object ("page_size_spinbutton");
        assert (object != null);
        page_size_spinbutton = (Gtk.SpinButton) object;

        object = builder.get_object ("pagination_start_spinbutton");
        assert (object != null);
        pagination_start_spinbutton = (Gtk.SpinButton) object;

        object = builder.get_object ("show_annotation_checkbutton");
        assert (object != null);
        show_annotation_checkbutton = (Gtk.CheckButton) object;

        object = builder.get_object ("initial_input_mode_combobox");
        assert (object != null);
        initial_input_mode_combobox = (Gtk.ComboBox) object;

        object = builder.get_object ("typing_rule_combobox");
        assert (object != null);
        typing_rule_combobox = (Gtk.ComboBox) object;

        object = builder.get_object ("add_dict_toolbutton");
        assert (object != null);
        Gtk.ToolButton add_dict_toolbutton = (Gtk.ToolButton) object;

        object = builder.get_object ("remove_dict_toolbutton");
        assert (object != null);
        Gtk.ToolButton remove_dict_toolbutton = (Gtk.ToolButton) object;

        object = builder.get_object ("up_dict_toolbutton");
        assert (object != null);
        Gtk.ToolButton up_dict_toolbutton = (Gtk.ToolButton) object;

        object = builder.get_object ("down_dict_toolbutton");
        assert (object != null);
        Gtk.ToolButton down_dict_toolbutton = (Gtk.ToolButton) object;

        object = builder.get_object ("dict_dialog");
        assert (object != null);
        dict_dialog = (Gtk.Dialog) object;

        object = builder.get_object ("input_mode_treeview");
        assert (object != null);
        input_mode_treeview = (Gtk.TreeView) object;

        object = builder.get_object ("shortcut_treeview");
        assert (object != null);
        shortcut_treeview = (Gtk.TreeView) object;

        object = builder.get_object ("add_shortcut_toolbutton");
        assert (object != null);
        add_shortcut_toolbutton = (Gtk.ToolButton) object;

        object = builder.get_object ("remove_shortcut_toolbutton");
        assert (object != null);
        remove_shortcut_toolbutton = (Gtk.ToolButton) object;

        object = builder.get_object ("shortcut_dialog");
        assert (object != null);
        shortcut_dialog = (Gtk.Dialog) object;

        object = builder.get_object ("shortcut_command_combobox");
        assert (object != null);
        shortcut_command_combobox = (Gtk.ComboBox) object;

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

        renderer = new DictCellRenderer ();
        column = new Gtk.TreeViewColumn.with_attributes ("dict", renderer,
                                                         "metadata", 0);
        dictionaries_treeview.append_column (column);

        model = new Gtk.ListStore (2,
                                   typeof (DictionaryMetadata),
                                   typeof (string));
        available_dictionaries_treeview.set_model (model);

        renderer = new DictCellRenderer ();
        column = new Gtk.TreeViewColumn.with_attributes ("dict", renderer,
                                                         "metadata", 0);
        available_dictionaries_treeview.append_column (column);

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

        use_custom_keymap_checkbutton.toggled.connect (() => {
                keymap_combobox.sensitive =
                    use_custom_keymap_checkbutton.get_active ();
            });

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
                        dialog,
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
            model.remove (iter);
        }
    }

    void add_shortcut () {
        if (shortcut_dialog.run () == Gtk.ResponseType.OK) {
            string command = combobox_get_active_string (
                shortcut_command_combobox,
                0);
            Gtk.TreeIter iter;
            var model = (Gtk.ListStore) shortcut_treeview.get_model ();
            model.append (out iter);
            model.set (iter, 0, command, 1, null, -1);
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
                if (old_event->modifiers == 0 &&
                    old_event->keyval in IGNORED_KEYVALS)
                    continue;
                keymap.set (old_event, null);
                ((Gtk.ListStore)model).remove (iter);
            }
        }
        try {
            shortcut_rule.write (shortcut_input_mode);
        } catch (Error e) {
            warning ("can't write shortcut: %s", e.message);
        }
    }

    void populate_dictionaries_treeview () {
        Variant? variant = preferences.get ("system_dictionaries");
        assert (variant != null);
        string[] strv = variant.dup_strv ();
        var model = (Gtk.ListStore) dictionaries_treeview.get_model ();
        foreach (var id in strv) {
            var metadata = preferences.get_dictionary_metadata (id);
            if (metadata != null) {
                Gtk.TreeIter iter;
                model.append (out iter);
                model.set (iter,
                           0, metadata,
                           1, dgettext (null, metadata.description));
            }
        }
    }

    void populate_available_dictionaries_treeview () {
        Variant? variant = preferences.get ("system_dictionaries");
        assert (variant != null);
        string[] strv = variant.dup_strv ();
        Set<string> enabled = new HashSet<string> ();
        foreach (var str in strv) {
            enabled.add (str);
        }

        var model = (Gtk.ListStore) available_dictionaries_treeview.get_model ();
        model.clear ();
        var available_dictionaries = preferences.list_available_dictionaries ();
        foreach (var metadata in available_dictionaries) {
            if (!enabled.contains (metadata.id)) {
                Gtk.TreeIter iter;
                model.append (out iter);
                model.set (iter,
                           0, metadata,
                           1, dgettext (null, metadata.description));
            }
        }
    }

    void populate_shortcut_treeview (Kkc.InputMode input_mode) {
        Variant? variant = preferences.get ("typing_rule");
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

    void add_dict () {
        populate_available_dictionaries_treeview ();
        if (dict_dialog.run () == Gtk.ResponseType.OK) {
            var model = (Gtk.ListStore) dictionaries_treeview.get_model ();
            var selection = available_dictionaries_treeview.get_selection ();
            Gtk.TreeModel available_model;
            var rows = selection.get_selected_rows (out available_model);
            foreach (var row in rows) {
                Gtk.TreeIter available_iter;
                if (available_model.get_iter (out available_iter, row)) {
                    DictionaryMetadata metadata;
                    available_model.get (available_iter, 0, out metadata, -1);
                    
                    Gtk.TreeIter iter;
                    model.append (out iter);
                    model.set (iter, 0, metadata);
                }
            }
            save_dictionaries ("system_dictionaries");
        }
        dict_dialog.hide ();
    }

    void remove_dict () {
        var selection = dictionaries_treeview.get_selection ();
        Gtk.TreeModel model;
        var rows = selection.get_selected_rows (out model);
        foreach (var row in rows) {
            Gtk.TreeIter iter;
            if (model.get_iter (out iter, row))
                ((Gtk.ListStore)model).remove (iter);
        }
        save_dictionaries ("system_dictionaries");
    }

    void up_dict () {
        var selection = dictionaries_treeview.get_selection ();
        Gtk.TreeModel model;
        Gtk.TreeIter iter;
        if (selection.get_selected (out model, out iter)) {
            Gtk.TreeIter prev = iter;
            if (model.iter_previous (ref prev)) {
                ((Gtk.ListStore)model).swap (iter, prev);
            }
        }
        save_dictionaries ("system_dictionaries");
    }

    void down_dict () {
        var selection = dictionaries_treeview.get_selection ();
        Gtk.TreeModel model;
        Gtk.TreeIter iter;
        if (selection.get_selected (out model, out iter)) {
            Gtk.TreeIter next = iter;
            if (model.iter_next (ref next)) {
                ((Gtk.ListStore)model).swap (iter, next);
            }
        }
        save_dictionaries ("system_dictionaries");
    }

    void load_spinbutton (string name,
                          Gtk.SpinButton spin) {
        Variant? variant = preferences.get (name);
        assert (variant != null);
        spin.value = (double) variant.get_int32 ();
        spin.value_changed.connect (() => {
                preferences.set (name, (int) spin.value);
            });
    }

    void load_togglebutton (string name,
                            Gtk.ToggleButton toggle) {
        Variant? variant = preferences.get (name);
        assert (variant != null);
        toggle.active = variant.get_boolean ();
        toggle.toggled.connect (() => {
                preferences.set (name,
                                 toggle.active);
            });
    }

    void load_combobox (string name,
                        Gtk.ComboBox combo,
                        int column) {
        Variant? variant = preferences.get (name);
        assert (variant != null);
        Gtk.TreeIter iter;
        var model = combo.get_model ();
        if (model.get_iter_first (out iter)) {
            var index = variant.get_int32 ();
            int _index;
            do {
                model.get (iter, column, out _index, -1);
                if (index == _index) {
                    combo.set_active_iter (iter);
                    break;
                }
            } while (model.iter_next (ref iter));
        }

        combo.changed.connect (() => {
                save_combobox (name, combo, column);
            });
    }

    void load_combobox_string (string name,
                               Gtk.ComboBox combo,
                               int column) {
        Variant? variant = preferences.get (name);
        assert (variant != null);
        Gtk.TreeIter iter;
        var model = combo.get_model ();
        if (model.get_iter_first (out iter)) {
            string str = variant.get_string ();
            do {
                string _str;
                model.get (iter, column, out _str, -1);
                if (str == _str) {
                    combo.set_active_iter (iter);
                    break;
                }
            } while (model.iter_next (ref iter));
        }

        combo.changed.connect (() => {
                save_combobox_string (name, combo, column);
            });
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
        load_combobox_string ("typing_rule", typing_rule_combobox, 0);
        load_combobox ("initial_input_mode", initial_input_mode_combobox, 1);
        load_combobox ("punctuation_style", punctuation_style_combobox, 1);
        load_togglebutton ("auto_correct", auto_correct_checkbutton);
        load_togglebutton ("use_custom_keymap", use_custom_keymap_checkbutton);
        load_combobox_string ("keymap", keymap_combobox, 0);

        load_spinbutton ("page_size", page_size_spinbutton);
        load_spinbutton ("pagination_start", pagination_start_spinbutton);
        load_togglebutton ("show_annotation", show_annotation_checkbutton);

        populate_dictionaries_treeview ();
        select_shortcut_section (Kkc.InputMode.HIRAGANA);
    }

    void save_dictionaries (string name) {
        var model = dictionaries_treeview.get_model ();
        Gtk.TreeIter iter;
        if (model.get_iter_first (out iter)) {
            ArrayList<string> dictionaries = new ArrayList<string> ();
            do {
                DictionaryMetadata metadata;
                model.get (iter, 0, out metadata, -1);
                dictionaries.add (metadata.id);
            } while (model.iter_next (ref iter));
            preferences.set (name, dictionaries.to_array ());
        }
    }

    void save_combobox (string name,
                        Gtk.ComboBox combo,
                        int column)
    {
        Gtk.TreeIter iter;
        if (combo.get_active_iter (out iter)) {
            int index;
            var model = combo.get_model ();
            model.get (iter, column, out index, -1);
            preferences.set (name, index);
        }
    }

    void save_combobox_string (string name,
                               Gtk.ComboBox combo,
                               int column)
    {
        Gtk.TreeIter iter;
        if (combo.get_active_iter (out iter)) {
            string str;
            var model = combo.get_model ();
            model.get (iter, column, out str, -1);
            preferences.set (name, str);
        }
    }

    public void run () {
        dialog.run ();
    }

    class DictCellRenderer : Gtk.CellRendererText {
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

        var config = bus.get_config ();
        if (config == null) {
            stderr.printf ("ibus-config component is not running!\n");
            return 1;
        }

        var setup = new Setup (new Preferences (config));

        setup.run ();
        return 0;
    }
}
