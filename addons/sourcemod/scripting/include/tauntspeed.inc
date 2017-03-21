#if defined _tauntspeed_included_
  #endinput
#endif
#define _tauntspeed_included_
 
/**
 * Sets the taunt speed on client given the vale
 *
 * @param client	An integer.
 * @param value		A float.
 * @return
 */
native void SetTauntSpeed(int client, float value);

/**
 * Removes the taunt speed on client
 *
 * @param client 	An integer.
 * @return
 */
native void RemoveTauntSpeed(int client);