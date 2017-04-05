#if defined _tauntspeed_included_
  #endinput
#endif
#define _tauntspeed_included_

public SharedPlugin __pl_tauntspeed = 
{
	name = "tauntspeed",
	file = "tauntspeed.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};
 
#if !defined REQUIRE_PLUGIN
public void __pl_tauntspeed_SetNTVOptional()
{
	MarkNativeAsOptional("SetGestureSpeed");
	MarkNativeAsOptional("SetVoicePitch");
	MarkNativeAsOptional("SetTauntAttackSpeed");
	MarkNativeAsOptional("SetGestureSpeed");
	MarkNativeAsOptional("RemoveGestureSpeed");
	MarkNativeAsOptional("RemoveVoicePitch");
}
#endif

/**
 * Sets the taunt gesture speed on client
 *
 * @param client	An integer.
 * @param value		A float.
 * @return
 */
native void SetGestureSpeed(int client, float value);

/**
 * Sets the voice pitch on client
 *
 * @param client 	An integer.
 * @return
 */
native void SetVoicePitch(int client, float value);

/**
 * Sets the taunt attack speed on client
 * Should be used on the TF2_OnConditionAdded forward
 *
 * @param client 	An integer.
 * @return
 */
native void SetTauntAttackSpeed(int client, float value);

/**
 * Removes the taunt gesture speed on client
 *
 * @param client 	An integer.
 * @return
 */
native void RemoveGestureSpeed(int client);

/**
 * Removes the voice pitch on client
 *
 * @param client 	An integer.
 * @return
 */
native void RemoveVoicePitch(int client);