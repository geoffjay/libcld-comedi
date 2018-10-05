/**
 * libcld
 * Copyright (c) 2015, Geoff Johnson, All rights reserved.
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 3.0 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library.
 */

using Comedi;
using Cld;

public class Cld.ComediDevice : Cld.AbstractDevice {

    private bool _is_open;
    [Description(nick="Open", blurb="The state of the Comedi device")]
    public bool is_open {
        get { return _is_open; }
    }

    /**
     * The comedi specific hardware device that this class will use.
     */
    public Comedi.Device dev;

    /**
     * Default construction
     */
    public ComediDevice () {
        objects = new Gee.TreeMap<string, Cld.Object> ();
        id = "dev0";
        hw_type = HardwareType.INPUT;
        driver = DeviceType.COMEDI;
        filename = "/dev/comedi0";
    }

    /**
     * Construction using an xml node
     */
    public ComediDevice.from_xml_node (Xml.Node *node) {
        objects = new Gee.TreeMap<string, Cld.Object> ();
        if (node->type == Xml.ElementType.ELEMENT_NODE &&
            node->type != Xml.ElementType.COMMENT_NODE) {
            id = node->get_prop ("id");

            /* iterate through node children */
            for (Xml.Node *iter = node->children;
                 iter != null;
                 iter = iter->next) {
                if (iter->name == "property") {
                    switch (iter->get_prop ("name")) {
                        case "filename":
                            filename = iter->get_content ();
                            break;
                        case "type":
                            var type = iter->get_content ();
                            if (type == "input")
                                hw_type = HardwareType.INPUT;
                            else if (type == "output")
                                hw_type = HardwareType.OUTPUT;
                            else if (type == "counter")
                                hw_type = HardwareType.COUNTER;
                            else if (type == "multifunction")
                                hw_type = HardwareType.MULTIFUNCTION;
                            break;
                        default:
                            break;
                    }
                }
                else if (iter->name == "object") {
                    switch (iter->get_prop ("type")) {
                        case "task":
                            var task = new Cld.ComediTask.from_xml_node (iter);
                            try {
                                add (task as Cld.Object);
                            } catch (GLib.Error e) {
                                critical (e.message);
                            }
                            break;
                        case "channel":
                            var channel = node_to_channel (iter);
                            try {
                                add (channel as Cld.Object);
                            } catch (GLib.Error e) {
                                critical (e.message);
                            }
                            break;
                        default:
                            break;
                    }
                }
            }
        }
    }

    public void set_is_open (bool state) {
        _is_open = state;
    }

    private Cld.Object? node_to_channel (Xml.Node *node) {
        Cld.Object object = null;

        var ctype = node->get_prop ("ctype");
        var direction = node->get_prop ("direction");

        if (ctype == "analog" && direction == "input") {
            object = new Cld.AIChannel.from_xml_node (node);
        } else if (ctype == "analog" && direction == "output") {
            object = new Cld.AOChannel.from_xml_node (node);
        } else if (ctype == "digital" && direction == "input") {
            object = new Cld.DIChannel.from_xml_node (node);
        } else if (ctype == "digital" && direction == "output") {
            object = new Cld.DOChannel.from_xml_node (node);
        }

        return object;
    }

    /**
     * {@inheritDoc}
     */
    public override bool open () {
        dev = new Comedi.Device (filename);
        if (dev != null) {
            _is_open = true;
            return true;
        } else {
            _is_open = false;
            return false;
        }
    }

    /**
     * {@inheritDoc}
     */
    public override bool close () {
        if (dev.close () == 0) {
            _is_open = false;
            return true;
        }
        else
            return false;
    }

    /**
     * Retrieve information about the Comedi device.
     */
    public Information info () {
        var info = new Information ();

        info.id = id;
        info.version_code = dev.get_version_code ();
        info.driver_name = dev.get_driver_name ();
        info.board_name = dev.get_board_name ();
        info.n_subdevices = dev.get_n_subdevices ();

        return info;
    }

//    /**
//     * {@inheritDoc}
//     */
//    public override string to_string () {
//        string str_data = "[%s] : Comedi device using file %s\n".printf (
//                            id, filename);
//        /* add the hardware and driver types later */
//        if (!objects.is_empty) {
//            foreach (var subdev in objects.values) {
//                str_data += "    %s".printf (subdev.to_string ());
//            }
//        }
//
//        return str_data;
//    }

    /**
     * Comedi device information class.
     */
    public class Information : GLib.Object {

        public string id { get; set; }

        public int version_code { get; set; }

        public string driver_name { get; set; }

        public string board_name { get; set; }

        public int n_subdevices { get; set; }

        /**
         * Default construction.
         */
        public Information () {
            id = "XXXX";
            version_code = -1;
            driver_name = "XXXX";
            board_name = "XXXX";
            n_subdevices = -1;
        }

        public string to_string () {
            string str_data = ("[%s] : Information for this Comedi device:\n" +
                                "   version code: %d\n" +
                                "   driver name: %s\n" +
                                "   board name: %s\n" +
                                "   n_subdevices: %d\n").printf (
                                    id, version_code, driver_name, board_name, n_subdevices);
            return str_data;
        }
    }
}
