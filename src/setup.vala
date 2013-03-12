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
    Gtk.ComboBox punctuation_style_combobox;
    Gtk.SpinButton page_size_spinbutton;
    Gtk.SpinButton pagination_start_spinbutton;
    Gtk.CheckButton show_annotation_checkbutton;
    Gtk.ComboBox initial_input_mode_combobox;
    Gtk.ComboBox typing_rule_combobox;

    // dict dialog
    Gtk.Dialog dict_dialog;
    Gtk.ComboBox dict_type_combobox;
    Gtk.HBox dict_data_hbox;
    Gtk.Widget dict_data_widget;
    Gtk.FileChooserButton dict_filechooserbutton;
    Gtk.Entry dict_entry;
    Gtk.SpinButton dict_spinbutton;

    Preferences preferences;
    
    public Setup (Preferences preferences) {
        this.preferences = preferences;

        var builder = new Gtk.Builder ();
        builder.set_translation_domain ("ibus-kkc");
        var ui_filename = Path.build_filename (Config.SETUPDIR,
                                            "ibus-kkc-preferences.ui");
        try {
            builder.add_from_file (ui_filename);
        } catch (GLib.Error e) {
            error ("can't load %s: %s", ui_filename, e.message);
        }

        // map widgets defined in ibus-kkc-preferences.ui
        Object? object;

        object = builder.get_object ("dialog");
        assert (object != null);
        dialog = (Gtk.Dialog) object;

        object = builder.get_object ("dictionaries_treeview");
        assert (object != null);
        dictionaries_treeview = (Gtk.TreeView) object;

        object = builder.get_object ("punctuation_style_combobox");
        assert (object != null);
        punctuation_style_combobox = (Gtk.ComboBox) object;

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

        object = builder.get_object ("add_dict_button");
        assert (object != null);
        Gtk.Button add_dict_button = (Gtk.Button) object;

        object = builder.get_object ("remove_dict_button");
        assert (object != null);
        Gtk.Button remove_dict_button = (Gtk.Button) object;

        object = builder.get_object ("up_dict_button");
        assert (object != null);
        Gtk.Button up_dict_button = (Gtk.Button) object;

        object = builder.get_object ("down_dict_button");
        assert (object != null);
        Gtk.Button down_dict_button = (Gtk.Button) object;

        object = builder.get_object ("dict_dialog");
        assert (object != null);
        dict_dialog = (Gtk.Dialog) object;

        object = builder.get_object ("dict_type_combobox");
        assert (object != null);
        dict_type_combobox = (Gtk.ComboBox) object;

        object = builder.get_object ("dict_data_hbox");
        assert (object != null);
        dict_data_hbox = (Gtk.HBox) object;
        
        dict_filechooserbutton = new Gtk.FileChooserButton (
            "dictionary file",
            Gtk.FileChooserAction.OPEN);
        dict_entry = new Gtk.Entry ();
        dict_spinbutton = new Gtk.SpinButton.with_range (0, 65535, 1);

        page_size_spinbutton.set_range (7.0, 16.0);
        page_size_spinbutton.set_increments (1.0, 1.0); 

        pagination_start_spinbutton.set_range (0.0, 7.0);
        pagination_start_spinbutton.set_increments (1.0, 1.0);

        Gtk.ListStore model;
        Gtk.CellRenderer renderer;
        Gtk.TreeViewColumn column;

        model = new Gtk.ListStore (1, typeof (PList));
        dictionaries_treeview.set_model (model);

        renderer = new TypeCellRenderer ();
        column = new Gtk.TreeViewColumn.with_attributes ("type", renderer,
                                                         "plist", 0);
        dictionaries_treeview.append_column (column);

        renderer = new DescCellRenderer ();
        column = new Gtk.TreeViewColumn.with_attributes ("desc", renderer,
                                                         "plist", 0);
        dictionaries_treeview.append_column (column);

        renderer = new Gtk.CellRendererText ();
        punctuation_style_combobox.pack_start (renderer, false);
        punctuation_style_combobox.set_attributes (renderer, "text", 0);

        renderer = new Gtk.CellRendererText ();
        initial_input_mode_combobox.pack_start (renderer, false);
        initial_input_mode_combobox.set_attributes (renderer, "text", 0);

        renderer = new Gtk.CellRendererText ();
        dict_type_combobox.pack_start (renderer, false);
        dict_type_combobox.set_attributes (renderer, "text", 0);

        model = new Gtk.ListStore (2, typeof (string), typeof (string));
        model.set_sort_column_id (1, Gtk.SortType.ASCENDING);
        typing_rule_combobox.set_model (model);
        var rules = Kkc.Rule.list ();
        foreach (var rule in rules) {
            Gtk.TreeIter iter;
            model.append (out iter);
            model.set (iter, 0, rule.name);
            model.set (iter, 1, rule.label);
        }

        renderer = new Gtk.CellRendererText ();
        typing_rule_combobox.pack_start (renderer, false);
        typing_rule_combobox.set_attributes (renderer, "text", 1);

        load ();

        add_dict_button.clicked.connect (add_dict);
        remove_dict_button.clicked.connect (remove_dict);
        up_dict_button.clicked.connect (up_dict);
        down_dict_button.clicked.connect (down_dict);

        var selection = dictionaries_treeview.get_selection ();
        selection.changed.connect (() => {
                int count = selection.count_selected_rows ();
                if (count > 0) {
                    remove_dict_button.sensitive = true;
                    up_dict_button.sensitive = true;
                    down_dict_button.sensitive = true;
                } else if (count == 0) {
                    remove_dict_button.sensitive = false;
                    up_dict_button.sensitive = false;
                    down_dict_button.sensitive = false;
                }
            });

        dict_type_combobox.changed.connect (() => {
                if (dict_data_widget != null) {
                    dict_data_hbox.remove (dict_data_widget);
                }
                string text = get_active_dict_type ();
                if (text == "System") {
                    dict_filechooserbutton.set_current_folder (
                        Path.build_filename (Config.DATADIR, "kkc"));
                    dict_data_widget = dict_filechooserbutton;
                } else if (text == "User") {
                    dict_filechooserbutton.set_current_folder (
                        Environment.get_home_dir ());
                    dict_data_widget = dict_filechooserbutton;
                } else {
                    warning ("unknown dictionary type: %s",
                             text);
                    assert_not_reached ();
                }
                dict_data_hbox.add (dict_data_widget);
                dict_data_hbox.show_all ();
                dict_data_hbox.sensitive = true;
            });
        dict_type_combobox.active = 0;
    }

    void populate_dictionaries_treeview () {
        Variant? variant = preferences.get ("dictionaries");
        assert (variant != null);
        string[] strv = variant.dup_strv ();
        var model = (Gtk.ListStore) dictionaries_treeview.get_model ();
        foreach (var str in strv) {
            PList plist;
            try {
                plist = new PList (str);
            } catch (PListParseError e) {
                warning ("can't parse plist %s: %s", str, e.message);
                continue;
            }
            Gtk.TreeIter iter;
            model.append (out iter);
            model.set (iter, 0, plist);
        }
    }

    string get_active_dict_type () {
        string text;
        Gtk.TreeIter iter;
        if (dict_type_combobox.get_active_iter (out iter)) {
            var model = (Gtk.ListStore) dict_type_combobox.get_model ();
            model.get (iter, 1, out text, -1);
        } else {
            assert_not_reached ();
        }
        return text;
    }

    void add_dict () {
        if (dict_dialog.run () == Gtk.ResponseType.OK) {
            PList? plist = null;
            string text = get_active_dict_type ();
            if (text == "System") {
                string? file = dict_filechooserbutton.get_filename ();
                if (file != null) {
                    try {
                        plist = new PList (
                            "type=file,file=%s,mode=readonly".printf (
                                PList.escape (file)));
                    } catch (PListParseError e) {
                        assert_not_reached ();
                    }
                }
            }
            else if (text == "User") {
                string? file = dict_filechooserbutton.get_filename ();
                if (file != null) {
                    try {
                        plist = new PList (
                            "type=file,file=%s,mode=readwrite".printf (
                                PList.escape (file)));
                    } catch (PListParseError e) {
                        assert_not_reached ();
                    }
                }
            }
            else {
                assert_not_reached ();
            }

            if (plist != null) {
                var model = (Gtk.ListStore) dictionaries_treeview.get_model ();
                Gtk.TreeIter iter;
                bool found = false;
                if (model.get_iter_first (out iter)) {
                    do {
                        PList _plist;
                        model.get (iter, 0, out _plist, -1);
                        if (_plist.to_string () == plist.to_string ()) {
                            found = true;
                        }
                    } while (!found && model.iter_next (ref iter));
                }
                if (!found) {
                    model.insert_with_values (out iter, int.MAX, 0, plist, -1);
                    save_dictionaries ("dictionaries");
                }
            }
        }
        dict_dialog.hide ();
    }

    void remove_dict () {
        var selection = dictionaries_treeview.get_selection ();
        Gtk.TreeModel model;
        var rows = selection.get_selected_rows (out model);
        foreach (var row in rows) {
            Gtk.TreeIter iter;
            if (model.get_iter (out iter, row)) {
                ((Gtk.ListStore)model).remove (iter);
            }
        }
        save_dictionaries ("dictionaries");
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
        save_dictionaries ("dictionaries");
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
        save_dictionaries ("dictionaries");
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

    void load () {
        populate_dictionaries_treeview ();

        load_spinbutton ("page_size",
                         page_size_spinbutton);
        load_spinbutton ("pagination_start",
                         pagination_start_spinbutton);

        load_togglebutton ("show_annotation",
                           show_annotation_checkbutton);

        load_combobox ("punctuation_style",
                       punctuation_style_combobox,
                       1);
        load_combobox ("initial_input_mode",
                       initial_input_mode_combobox,
                       1);

        load_combobox_string ("typing_rule",
                              typing_rule_combobox,
                              0);
    }

    void save_dictionaries (string name) {
        var model = dictionaries_treeview.get_model ();
        Gtk.TreeIter iter;
        if (model.get_iter_first (out iter)) {
            ArrayList<string> dictionaries = new ArrayList<string> ();
            do {
                PList plist;
                model.get (iter, 0, out plist, -1);
                dictionaries.add (plist.to_string ());
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

    class TypeCellRenderer : Gtk.CellRendererText {
        private PList _plist;
        public PList plist {
            get {
                return _plist;
            }
            set {
                _plist = value;
                var type = _plist.get ("type");
                if (type == "file") {
                    var mode = _plist.get ("mode") ?? "readonly";
                    if (mode == "readonly")
                        text = _("system");
                    else
                        text = _("user");
                }
            }
        }
    }

    class DescCellRenderer : Gtk.CellRendererText {
        private PList _plist;
        public PList plist {
            get {
                return _plist;
            }
            set {
                _plist = value;
                var type = _plist.get ("type");
                if (type == "file") {
                    text = _plist.get ("file");
                }
            }
        }
    }

    public static int main (string[] args) {
		Gtk.init (ref args);
		IBus.init ();
        Kkc.init ();

        var bus = new IBus.Bus ();
        var config = bus.get_config ();
		var setup = new Setup (new Preferences (config));

		setup.run ();
		return 0;
	}
}
