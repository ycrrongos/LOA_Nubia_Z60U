#!/usr/bin/env python3
"""Stub org.kde.KWin /Session so plasma-shutdown can finish without kwin_x11.

Alpine kwin 6.7+ ships Wayland-only; Plasma X11 reboot then fails with
"KWin failed to complete logout". This provides closeSession() => true.
"""
import sys

from PyQt6.QtCore import QCoreApplication, QObject, pyqtSlot
from PyQt6.QtDBus import QDBusConnection, QDBusAbstractAdaptor


class SessionAdaptor(QDBusAbstractAdaptor):
    Q_CLASSINFO("D-Bus Interface", "org.kde.KWin.Session")

    def __init__(self, parent):
        super().__init__(parent)

    @pyqtSlot(result=bool)
    def closeSession(self) -> bool:
        print("cerro-kwin-session-stub: closeSession()", flush=True)
        return True


class SessionObj(QObject):
    def __init__(self):
        super().__init__()
        self._adaptor = SessionAdaptor(self)


def main() -> int:
    app = QCoreApplication(sys.argv)
    bus = QDBusConnection.sessionBus()
    if not bus.isConnected():
        print("no session bus", file=sys.stderr)
        return 1
    # Only register if real KWin is absent
    if bus.interface().isServiceRegistered("org.kde.KWin"):
        print("org.kde.KWin already present; stub exiting", flush=True)
        return 0
    obj = SessionObj()
    if not bus.registerObject("/Session", obj):
        print("registerObject /Session failed", file=sys.stderr)
        return 1
    if not bus.registerService("org.kde.KWin"):
        print("registerService org.kde.KWin failed", file=sys.stderr)
        return 1
    print("cerro-kwin-session-stub: serving org.kde.KWin /Session", flush=True)
    return app.exec()


if __name__ == "__main__":
    raise SystemExit(main())
