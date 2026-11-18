#!/usr/bin/env python3
# SPDX-FileCopyrightText: 2026 Outcrop Inc
# SPDX-License-Identifier: GPL-3.0-or-later
# File GUID: f27e68c8-2510-40b5-be6d-5a24d9ee5afc
# COMPONENT: macOS resource counters
# PURPOSE: Read public proc_pid_rusage v4 metadata without reading process memory contents.
import ctypes
import sys


class ResourceUsage(ctypes.Structure):
    """SDK sys/resource.h rusage_info_v4 layout. Energy counters retain their opaque OS units."""
    _fields_ = [("ri_uuid", ctypes.c_uint8 * 16)] + [
        (name, ctypes.c_uint64) for name in (
            "ri_user_time ri_system_time ri_pkg_idle_wkups ri_interrupt_wkups ri_pageins ri_wired_size "
            "ri_resident_size ri_phys_footprint ri_proc_start_abstime ri_proc_exit_abstime ri_child_user_time "
            "ri_child_system_time ri_child_pkg_idle_wkups ri_child_interrupt_wkups ri_child_pageins "
            "ri_child_elapsed_abstime ri_diskio_bytesread ri_diskio_byteswritten ri_cpu_time_qos_default "
            "ri_cpu_time_qos_maintenance ri_cpu_time_qos_background ri_cpu_time_qos_utility ri_cpu_time_qos_legacy "
            "ri_cpu_time_qos_user_initiated ri_cpu_time_qos_user_interactive ri_billed_system_time "
            "ri_serviced_system_time ri_logical_writes ri_lifetime_max_phys_footprint ri_instructions ri_cycles "
            "ri_billed_energy ri_serviced_energy ri_interval_max_phys_footprint ri_runnable_time"
        ).split()
    ]


def read_usage(pid: int) -> dict | None:
    if sys.platform != "darwin":
        return None
    library = ctypes.CDLL("/usr/lib/libproc.dylib", use_errno=True)
    library.proc_pid_rusage.argtypes = [ctypes.c_int, ctypes.c_int, ctypes.c_void_p]
    value = ResourceUsage()
    if library.proc_pid_rusage(pid, 4, ctypes.byref(value)) != 0:
        return None
    return {"physicalBytes": value.ri_phys_footprint,
            "lifetimePeakPhysicalBytes": value.ri_lifetime_max_phys_footprint,
            "osEnergyCounter": value.ri_billed_energy}
