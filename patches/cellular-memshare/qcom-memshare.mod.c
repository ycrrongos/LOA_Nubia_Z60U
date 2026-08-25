#include <linux/module.h>
#include <linux/export-internal.h>
#include <linux/compiler.h>

MODULE_INFO(name, KBUILD_MODNAME);

__visible struct module __this_module
__section(".gnu.linkonce.this_module") = {
	.name = KBUILD_MODNAME,
	.init = init_module,
#ifdef CONFIG_MODULE_UNLOAD
	.exit = cleanup_module,
#endif
	.arch = MODULE_ARCH_INIT,
};


MODULE_INFO(depends, "qmi_helpers");

MODULE_ALIAS("of:N*T*Cqcom,memshare-peripheral");
MODULE_ALIAS("of:N*T*Cqcom,memshare-peripheralC*");
MODULE_ALIAS("of:N*T*Cqcom,memshare");
MODULE_ALIAS("of:N*T*Cqcom,memshareC*");
