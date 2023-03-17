include $(TOPDIR)/rules.mk

PKG_NAME:=ncm-fibocom
PKG_VERSION:=0.0.1
PKG_RELEASE:=5
PKG_MAINTAINER:=bulanovk

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
  PKGARCH:=all
  DEPENDS:=+comgt +kmod-usb-acm +kmod-usb-net-cdc-ncm
  TITLE:=Fibocom L850/L860 scripts
endef

define Package/$(PKG_NAME)/description
	Simple connect to cellular for Fibocom L850/L860 module (Intel XMM LTE-A 7360/7560)
endef



define Build/Prepare
endef

define Build/Configure
endef

define Build/Compile

endef


define Package/$(PKG_NAME)/install
	$(CP) ./root/* $(1)/
	chmod +x $(1)/lib/netifd/proto/intel_ncm.sh
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
