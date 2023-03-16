"""Functions related to components.

See proto definitions for descriptions of arguments.
"""

# Needed to load from @proto. Add @unused to silence lint.
load("//config/util/bindings/proto.star", "protos")
load(
    "@proto//chromiumos/config/api/component.proto",
    comp_pb = "chromiumos.config.api",
)
load(
    "@proto//chromiumos/config/api/component_id.proto",
    comp_id_pb = "chromiumos.config.api",
)

def _create_usb(vendor_id, product_id, bcd_device):
    """Builds a Interface.Usb proto."""
    usb = comp_pb.Component.Interface.Usb(
        vendor_id = vendor_id,
        product_id = product_id,
        bcd_device = bcd_device,
    )
    component_id = comp_id_pb.ComponentId(
        value = ":".join([vendor_id, product_id, bcd_device]),
    )
    return component_id, usb

def _create_pci(vendor_id, device_id, revision_id):
    """Builds a Interface.Pci proto."""
    pci = comp_pb.Component.Interface.Pci(
        vendor_id = vendor_id,
        device_id = device_id,
        revision_id = revision_id,
    )

    component_id = comp_id_pb.ComponentId(
        value = ":".join([vendor_id, device_id, revision_id]),
    )
    return component_id, pci

def _create_display_panel(
        display_vendor,
        product_id,
        product_name = None,
        inches = None,
        width_px = None,
        height_px = None,
        pixels_per_in = None):
    """Builds a Component.DisplayPanel proto for touchscreen."""
    vendor_code = display_vendor.display_panel_vendor.vendor_code
    id = comp_id_pb.ComponentId(value = "_".join([vendor_code, product_id]))
    return comp_pb.Component(
        id = id,
        name = product_name or product_id,
        manufacturer_id = display_vendor.id,
        display_panel = comp_pb.Component.DisplayPanel(
            product_id = product_id,
            properties = comp_pb.Component.DisplayPanel.Properties(
                diagonal_milliinch = inches * 1000,
                width_px = width_px,
                height_px = height_px,
                pixels_per_in = pixels_per_in,
            ),
        ),
    )

def _create_rounded_corners(
        top_left,
        top_right = None,
        bottom_left = None,
        bottom_right = None):
    """Creates a Component.DisplayPanel.Properties.RoundedCorners."""
    if top_right == None:
        top_right = top_left
    if bottom_left == None:
        bottom_left = top_left
    if bottom_right == None:
        bottom_right = bottom_left
    return comp_pb.Component.DisplayPanel.Properties.RoundedCorners(
        top_left = comp_pb.Component.DisplayPanel.Properties.RoundedCorners.RoundedCorner(radius_px = top_left),
        top_right = comp_pb.Component.DisplayPanel.Properties.RoundedCorners.RoundedCorner(radius_px = top_right),
        bottom_left = comp_pb.Component.DisplayPanel.Properties.RoundedCorners.RoundedCorner(radius_px = bottom_left),
        bottom_right = comp_pb.Component.DisplayPanel.Properties.RoundedCorners.RoundedCorner(radius_px = bottom_right),
    )

def _create_touch(
        product_id,
        fw_version,
        product_series = None):
    """Builds a Component.Touch proto."""
    return comp_pb.Component.Touch(
        product_id = product_id,
        fw_version = fw_version,
        product_series = product_series,
    )

def _create_touch_id(
        touch_vendor,
        product_id,
        fw_version):
    return comp_id_pb.ComponentId(
        value = "_".join([touch_vendor.name, product_id, fw_version]),
    )

def _create_touchscreen(
        touch_vendor,
        product_id,
        fw_version,
        product_name = None,
        product_series = None):
    """Builds a Component.Touch proto for touchscreen."""
    id = _create_touch_id(touch_vendor, product_id, fw_version)
    touchscreen = _create_touch(
        product_id,
        fw_version,
        product_series,
    )
    return comp_pb.Component(
        id = id,
        name = product_name,
        manufacturer_id = touch_vendor.id,
        touchscreen = touchscreen,
    )

def _create_touchpad(
        touch_vendor,
        product_id,
        fw_version,
        product_name = None,
        product_series = None):
    """Builds a Component.Touch proto for touchpad."""
    id = _create_touch_id(touch_vendor, product_id, fw_version)
    touchpad = _create_touch(
        product_id,
        fw_version,
        product_series,
    )
    return comp_pb.Component(
        id = id,
        name = product_name,
        manufacturer_id = touch_vendor.id,
        touchpad = touchpad,
    )

def _create_soc_family(name, arch = comp_pb.Component.Soc.X86_64):
    """Builds a Component.Soc.Family proto."""
    return comp_pb.Component.Soc.Family(
        arch = arch,
        name = name,
    )

def _create_soc_model(family, model, cores, id):
    """Builds a Component proto for an Soc."""
    id_value = comp_id_pb.ComponentId(value = id)
    soc = comp_pb.Component.Soc(
        family = family,
        model = model,
        cores = cores,
    )
    return comp_pb.Component(id = id_value, soc = soc)

def _create_bt(vendor_id, product_id, bcd_device):
    """Builds a Component proto for Bluetooth."""
    component_id, usb = _create_usb(
        vendor_id = vendor_id,
        product_id = product_id,
        bcd_device = bcd_device,
    )
    return comp_pb.Component(
        id = component_id,
        bluetooth = comp_pb.Component.Bluetooth(usb = usb),
    )

def _create_cellular(vendor_id, product_id, bcd_device):
    """Builds a Component proto for Cellular device."""
    component_id, usb = _create_usb(
        vendor_id = vendor_id,
        product_id = product_id,
        bcd_device = bcd_device,
    )
    return comp_pb.Component(
        id = component_id,
        cellular = comp_pb.Component.Cellular(usb = usb),
    )

def _create_wifi(vendor_id, device_id, revision_id):
    """Builds a Component proto for Wifi."""
    component_id, pci = _create_pci(
        vendor_id = vendor_id,
        device_id = device_id,
        revision_id = revision_id,
    )
    return comp_pb.Component(
        id = component_id,
        wifi = comp_pb.Component.Wifi(pci = pci),
    )

_qual_status = struct(
    REQUESTED = comp_pb.Component.Qualification.REQUESTED,
    TECHNICALLY_QUALIFIED = comp_pb.Component.Qualification.TECHNICALLY_QUALIFIED,
    QUALIFIED = comp_pb.Component.Qualification.QUALIFIED,
)

def _create_qual(component_id, status = _qual_status.REQUESTED):
    """Builds a Component.Qualification proto."""
    return comp_pb.Component.Qualification(
        component_id = component_id,
        status = status,
    )

def _create_quals(component_ids, status = _qual_status.REQUESTED):
    """Builds a Component.Qualification proto for each of component_ids."""
    return [_create_qual(id, status) for id in component_ids]

def _create_amplifier(name):
    """Builds a Component.Amplifier proto."""
    return comp_pb.Component.Amplifier(
        name = name,
    )

def _create_audio_codec(name):
    """Builds a Component.AudioCodec proto."""
    return comp_pb.Component.AudioCodec(
        name = name,
    )

_BATTERY_TECHNOLOGY = struct(
    TECH_UNKNOWN = comp_pb.Component.Battery.TECH_UNKNOWN,
    LI_ION = comp_pb.Component.Battery.LI_ION,
)

def _create_battery(model, technology):
    return comp_pb.Component(
        battery = comp_pb.Component.Battery(
            model = model,
            technology = technology,
        ),
    )

def _create_flash_chip(part_number):
    """Build a Component.FlashChip proto."""
    return comp_pb.Component.FlashChip(
        part_number = part_number,
    )

def _create_embedded_controller(part_number):
    """Build a Component.EmbeddedController proto."""
    return comp_pb.Component.EmbeddedController(
        part_number = part_number,
    )

def _create_storage_mmc(emmc5_fw_ver, manfid, name, oemid, prv, sectors):
    """Build a Component.Storage proto for an MMC device."""
    return comp_pb.Component.Storage(
        emmc5_fw_ver = emmc5_fw_ver,
        manfid = manfid,
        name = name,
        oemid = oemid,
        prv = prv,
        sectors = sectors,
        type = comp_pb.Component.Storage.EMMC,
    )

def _create_tpm(manufacturer_info, version):
    """Build a Component.Tpm proto."""
    return comp_pb.Component.Tpm(
        manufacturer_info = manufacturer_info,
        version = version,
    )

def _append_display_panel(
        component_list,
        vendor_list,
        display_vendor,
        product_id,
        product_name = None,
        inches = None,
        width_px = None,
        height_px = None,
        pixels_per_in = None):
    if not display_vendor in vendor_list:
        vendor_list.append(display_vendor)
    component_list.append(
        _create_display_panel(
            display_vendor = display_vendor,
            product_id = product_id,
            product_name = product_name,
            inches = inches,
            width_px = width_px,
            height_px = height_px,
            pixels_per_in = pixels_per_in,
        ),
    )

def _append_touchpad(
        component_list,
        vendor_list,
        touch_vendor,
        product_id,
        fw_version,
        product_name = None,
        product_series = None):
    if not touch_vendor in vendor_list:
        vendor_list.append(touch_vendor)
    component_list.append(
        _create_touchpad(
            touch_vendor = touch_vendor,
            product_id = product_id,
            fw_version = fw_version,
            product_name = product_name,
            product_series = product_series,
        ),
    )

def _append_touchscreen(
        component_list,
        vendor_list,
        touch_vendor,
        product_id,
        fw_version,
        product_name = None,
        product_series = None):
    if not touch_vendor in vendor_list:
        vendor_list.append(touch_vendor)
    component_list.append(
        _create_touchscreen(
            touch_vendor = touch_vendor,
            product_id = product_id,
            fw_version = fw_version,
            product_name = product_name,
            product_series = product_series,
        ),
    )

def _append_battery(
        component_list,
        vendor_list,
        battery_vendor,
        model,
        technology = _BATTERY_TECHNOLOGY.LI_ION):
    if not battery_vendor in vendor_list:
        vendor_list.append(battery_vendor)
    component_list.append(
        _create_battery(
            model = model,
            technology = technology,
        ),
    )

comp = struct(
    create_soc_family = _create_soc_family,
    create_soc_model = _create_soc_model,
    create_bt = _create_bt,
    create_cellular = _create_cellular,
    create_display_panel = _create_display_panel,
    create_rounded_corners = _create_rounded_corners,
    create_touchscreen = _create_touchscreen,
    create_touchpad = _create_touchpad,
    create_wifi = _create_wifi,
    create_qual = _create_qual,
    create_quals = _create_quals,
    create_amplifier = _create_amplifier,
    create_audio_codec = _create_audio_codec,
    create_battery = _create_battery,
    create_ec_flash_chip = _create_flash_chip,
    create_flash_chip = _create_flash_chip,
    create_embedded_controller = _create_embedded_controller,
    create_storage_mmc = _create_storage_mmc,
    create_tpm = _create_tpm,
    qual_status = _qual_status,
    create_usb = _create_usb,
    create_pci = _create_pci,
    append_battery = _append_battery,
    append_display_panel = _append_display_panel,
    append_touchpad = _append_touchpad,
    append_touchscreen = _append_touchscreen,
    battery_technology = _BATTERY_TECHNOLOGY,
)
