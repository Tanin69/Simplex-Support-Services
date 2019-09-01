#include "script_component.hpp"

params [
	["_vehicle",objNull,[objNull]],
	["_callsign","",[""]],
	["_respawnTime",parseNumber SSS_DEFAULT_RESPAWN_TIME,[0]]
];

if (!local _vehicle) exitWith {_this remoteExecCall [QFUNC(addTransport),_vehicle];};

// Validation
private _side = side _vehicle;
if (_callsign isEqualTo "") then {_callsign = getText (configFile >> "CfgVehicles" >> typeOf _vehicle >> "displayName");};

if !(_side in [west,east,resistance]) exitWith {SSS_ERROR_2("Invalid side: %1 (%2)",_callsign,_vehicle)};
if ({isPlayer _x} count crew _vehicle > 0) exitWith {SSS_ERROR_2("Cannot assign players: %1 (%2)",_callsign,_vehicle)};
if (_vehicle in (missionNamespace getVariable [format ["SSS_transport_%1",_side],[]])) exitWith {SSS_ERROR_2("Vehicle already assigned: %1 (%2)",_callsign,_vehicle)};
if (!alive driver _vehicle) exitWith {SSS_ERROR_2("No driver in vehicle: %1 (%2)",_callsign,_vehicle)};

// Basic setup
private _group = group _vehicle;
private _base = createVehicle ["Land_HelipadEmpty_F",[0,0,0],[],0,"CAN_COLLIDE"];
_base setPosASL (getPosASL _vehicle);
SET_VEHICLE_TRAITS_PHYSICAL(_vehicle,_group,_base,_side,"transport",_callsign,_respawnTime)
CREATE_TASK_MARKER(_vehicle,"mil_end","Transport",_callsign)

// Service specific setup
_vehicle setVariable ["SSS_icon",ICON_HELI,true];
_vehicle setVariable ["SSS_awayFromBase",false,true];
_vehicle setVariable ["SSS_onTask",false,true];
_vehicle setVariable ["SSS_interrupt",false,true];
_vehicle setVariable ["SSS_combatMode",0,true];
_vehicle setVariable ["SSS_speedMode",1,true];
_vehicle setVariable ["SSS_flyingHeight",80,true];
_vehicle setVariable ["SSS_needConfirmation",false,true];
_vehicle setVariable ["SSS_signalApproved",false,true];
_vehicle setVariable ["SSS_deniedSignals",[],true];
_vehicle flyInHeight 80;
private _fries = _vehicle getVariable ["ace_fastroping_FRIES",objnull]; // FRIES makes AI pilots a nightmare
if (!isNull _fries) then {deleteVehicle _fries;};

// Assignment
[true,format ["SSS_transport_%1",_side],_vehicle] remoteExecCall [QEFUNC(common,editServiceArray),2];
[_vehicle,["Deleted",{_this call EFUNC(common,deleted);}]] remoteExecCall ["addEventHandler",0];
_vehicle addMPEventHandler ["MPKilled",{[_this # 0] call EFUNC(common,respawn);}];
(driver _vehicle) addMPEventHandler ["MPKilled",{[vehicle (_this # 0),true] call EFUNC(common,respawn);}];
[_vehicle,"GetOut",{
	params ["_vehicle","_role","_unit","_turret"];

	if (_role == "driver") then {
		_vehicle removeEventHandler [_thisType,_thisID];
		[_vehicle,true] call EFUNC(common,respawn);
	};
}] remoteExecCall ["CBA_fnc_addBISEventHandler",2];

// CBA Event
private _JIPID = ["SSS_supportVehicleAdded",_vehicle] call CBA_fnc_globalEventJIP;
[_JIPID,_vehicle] call CBA_fnc_removeGlobalEventJIP;
_vehicle setVariable ["SSS_addedJIPID",_JIPID,true];