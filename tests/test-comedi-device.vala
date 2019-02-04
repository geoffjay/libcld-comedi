/**
 * libcld-comedi
 * Copyright (c) 2015-2018, Geoff Johnson, All rights reserved.
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

using Cld;

public class ComediDeviceTests : ObjectTests {

    public ComediDeviceTests () {
        base ("ComediDevice");
        add_test ("[ComediDevice] ...", test_foo);
    }

    public override void set_up () {
//        dev = new ComediDevice ();
//        Device test_object = dev;
        }

    public override void tear_down () {
        test_object = null;
    }

    private void test_foo () {
//        var test_device = test_object as Cld.AbstractDevice;

        // Check the Device exists
//        assert (test_device != null);

//        test_device.do_something ();
//        assert (test_device. == );
//        assert (test_device. == );
    }
}
