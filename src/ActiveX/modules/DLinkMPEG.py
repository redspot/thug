# D-Link MPEG4 SHM Audio Control
# CVE-NOMATCH

import logging
log = logging.getLogger("Thug")

def SetUrl(self, val):
    self.__dict__['Url'] = val
    if len(val) > 1024:
        log.MAEC.add_behavior_warn('DLinkMPEG overflow in Url property')

