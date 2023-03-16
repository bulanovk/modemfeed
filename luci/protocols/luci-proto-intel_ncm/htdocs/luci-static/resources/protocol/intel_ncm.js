'use strict';
'require ui';
'require uci';
'require rpc';
'require form';
'require network';

return network.registerProtocol('intel_ncm', {
	getI18n: function () {
		return _('Intel NCM');
	},

	getIfname: function () {
		return this._ubus('l3_device') || this.sid;
	},

	getOpkgPackage: function () {
		return 'intel_ncm';
	},

	isFloating: function () {
		return true;
	},

	isVirtual: function () {
		return true;
	},

	getDevices: function () {
		return null;
	},

	containsDevice: function (ifname) {
		return (network.getIfnameOf(ifname) == this.getIfname());
	},

	renderFormOptions: function (s) {
		var o;

		o = s.taboption('general', form.Value, 'apn', _('APB'), _('Required. APN name'));
        o = s.taboption('general', form.Value, 'device', _('Modem Port'), _('Required. AT Serial port of Intel Modem to perform communication'));
		o.rmempty = false;

	},

	deleteConfiguration: function () {
		uci.sections('network', 'xmm%s'.format(this.sid), function (s) {
			uci.remove('network', s['.name']);
		});
	}
});
