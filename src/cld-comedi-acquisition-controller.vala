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

/**
 * A class with methods for managing data aquisition Device and Task objects from
 * within a Cld.Context.
 *
 * Data from multiple Task sources is combined by multiplexer which feed a data
 * to a pipe or XXX (TBD) socket.
 */
using Comedi;

public class Cld.AcquisitionController : Cld.AbstractController {
    /**
     * A collection of tasks and an ipc defines a multiplexer.
     * All of the multiplexers are in this array.
     */
    private Gee.Map<string, Cld.Object> multiplexers;

    /**
     * The tasks that are contained in this.
     */
    private Gee.Map<string, Cld.Object> tasks;

    /**
     * The devices that are contained in this.
     */
    private Gee.Map<string, Cld.Object> devices;

    /**
     * Construction using an xml node
     */
    public Cld.AcquisitionController.from_xml_node (Xml.Node *node) {
        string value;

        if (node->type == Xml.ElementType.ELEMENT_NODE &&
            node->type != Xml.ElementType.COMMENT_NODE) {
            _id = node->get_prop ("id");
            /* iterate through node children */
            for (Xml.Node *iter = node->children; iter != null; iter = iter->next) {
                if (iter->name == "property") {
                    switch (iter->get_prop ("name")) {
                        case "fifo":
                            fifos.set (iter->get_content (), -1);
                            break;
                        default:
                            break;
                    }
                } else if (iter->name == "object") {
                    switch (iter->get_prop ("type")) {
                        case "device":
                            if (iter->get_prop ("driver") == "comedi") {
                                var dev = new Cld.ComediDevice.from_xml_node (iter);
                                (dev as Cld.ComediDevice).open ();
                                try {
                                    add (dev);
                                } catch (Cld.Error.KEY_EXISTS e) {
                                    error (e.message);
                                }
                            }
                            break;
                        case "multiplexer":
                            var mux = new Cld.Multiplexer.from_xml_node (iter);
                            try {
                                add (mux);
                            } catch (Cld.Error.KEY_EXISTS e) {
                                error (e.message);
                            }
                            break;
                        default:
                            break;
                    }
                }
            }
        }
    }

    /**
     * Launches acquisition by passing control onto internal multiplexers.
     *
     * FIXME: This should correctly launch all associated devices, tasks, and
     *        multiplexers regardless of task type so that the user application
     *        doesn't have to manually.
     *
     * FIXME: There should be an associated stop method to close devices and
     *        perform any acquisition halt that's needed.
     */
    public void run () {
        foreach (var multiplexer in multiplexers.values) {
            (multiplexer as Cld.Multiplexer).run ();
        }
    }

    public void stop () {
        foreach (var multiplexer in multiplexers.values) {
            (multiplexer as Cld.Multiplexer).stop ();
        }
    }

    /**
     * {@inheritDoc}
     */
    public override void generate () {
        debug ("Loading tasks");
        // FIXME: Crashes here!
        tasks = get_object_map (typeof (Cld.ComediTask));
        debug ("Loading devices");
        devices = get_object_map (typeof (Cld.ComediDevice));
        debug ("Loading multiplexers");
        multiplexers = get_object_map (typeof (Cld.Multiplexer));
        generate_multiplexers ();
    }

    /**
     * Update task fifo lists in preparation for logging.
     * @param log A log that is requesting data.
     * @param fname The uri of a named pipe for inter-process communication.
     */
    public void new_fifo (Cld.Log log, string fname) {
        /* Check if logged channels are from a streaming acquisition */
        foreach (var column in (log as Cld.Container).get_children (typeof (Cld.Column)).values) {
            var uri = (column as Cld.Column).channel.uri;
            var tasks = get_object_map (typeof (Cld.ComediTask));

            foreach (var task in tasks.values) {
                if (((task as Cld.ComediTask).exec_type == "streaming") &&
                        ((task as Cld.ComediTask).get_chrefs ().contains (uri))) {
                    (task as Cld.ComediTask).fifos.set (fname, -1);
                }
            }
        }
    }

    /**
     * Memory map the devices that this multiplexer uses.
     */
    private void generate_multiplexers () {
        foreach (var multiplexer in multiplexers.values) {
            (multiplexer as Cld.Multiplexer).generate ();
        }
    }
}
