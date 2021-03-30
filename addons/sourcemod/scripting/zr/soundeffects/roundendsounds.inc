/*
 * ============================================================================
 *
 *  Zombie:Reloaded
 *
 *  File:		  roundendsounds.inc
 *  Type:		  Core 
 *  Description:   Round End sound effects.
 *
 *  Copyright (C) 2009-2013  Greyscale, Richard Helgeby
 *
 *  This program is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * ============================================================================
 */

/**
 * @section Defines for min/max round wim human sound file index.
 */
#define SOUND_ROUNDENDCT_PATH "roundend/humanswin/humans_win%d.mp3" // %d is sound file index
#define SOUND_ROUNDENDCT_MIN 1
#define SOUND_ROUNDENDCT_MAX 4

/**
 * @endsection
 */

/**
 * @section Defines for min/max round wim zombies sound file index.
 */
#define SOUND_ROUNDENDT_PATH "roundend/zombiewin/zombie_win%d.mp3" // %d is sound file index
#define SOUND_ROUNDENDT_MIN 1
#define SOUND_ROUNDENDT_MAX 4

/**
 * @endsection
 */

/**
 * Zombie sound types
 */
enum RoundEndSounds
{
	HumansWinCt, /** Human Wim */
	ZombisWimT, /** Zombie's Win */
}

bool:RoundEndSoundsGetRandomSound(String:soundre[], RoundEndSounds:soundtype)
{
	new soundroundmin;
	new soundroundmax;
	decl String:soundrepath[SOUND_MAX_PATH];
	
	switch(soundtype)
	{
		// Find HumansWin sound.
		case HumansWinCt:
		{
			// Copy min and max
			soundroundmin = SOUND_ROUNDENDCT_MIN;
			soundroundmax = SOUND_ROUNDENDCT_MAX;
			
			// Copy path
			strcopy(soundrepath, sizeof(soundrepath), SOUND_ROUNDENDCT_PATH);
		}
		// Find ZombisWim sound.
		case ZombisWimT:
		{
			// Copy min and max
			soundroundmin = SOUND_ROUNDENDT_MIN;
			soundroundmax = SOUND_ROUNDENDT_MAX;
			
			// Copy path
			strcopy(soundrepath, sizeof(soundrepath), SOUND_ROUNDENDT_PATH);
		}
		// Invalid case given.
		default:
		{
			// No handled case was given.
			return false;
		}
	}
	
	// Pick a random integer between min and max sound file index.
	new randresound = GetRandomInt(soundroundmin, soundroundmax);
	
	// Format random index into sound path.
	Format(soundre, SOUND_MAX_PATH, soundrepath, randresound);
	
	// Found sound.
	return true;
}

RoundEndSoundsSoundOnMapStart()
{
	int countCT = 1;
	int countTR = 1;
	char roundendCTdir[PLATFORM_MAX_PATH];
	char roundendTRdir[PLATFORM_MAX_PATH];

	Format(roundendCTdir, sizeof(roundendCTdir), "sound/roundend/humanswin/humans_win%i.mp3", countCT);
	Format(roundendTRdir, sizeof(roundendTRdir), "sound/roundend/zombiewin/zombie_win%i.mp3", countTR);

	while(FileExists(roundendCTdir))
	{
		AddFileToDownloadsTable(roundendCTdir);
		ReplaceString(roundendCTdir, sizeof(roundendCTdir), "sound/", "");
		// Precache sound before playing.// Emit sound from client.
		PrecacheSound(roundendCTdir);
		Format(roundendCTdir, sizeof(roundendCTdir), "sound/roundend/humanswin/humans_win%i.mp3", countCT);

		countCT++;
	}

	while(FileExists(roundendTRdir))
	{
		AddFileToDownloadsTable(roundendTRdir);
		ReplaceString(roundendTRdir, sizeof(roundendTRdir), "sound/", "");
		// Precache sound before playing.// Emit sound from client.
		PrecacheSound(roundendTRdir);
		Format(roundendTRdir, sizeof(roundendTRdir), "sound/roundend/zombiewin/zombie_win%i.mp3", countTR);

		countTR++;
	}
}

RoundEndSoundsSoundFromClient(x, const String:soundre[], Float:level)
{
	if (IsClientInGame(x) && !IsFakeClient(x))
	{
		// Emit sound from client.
		EmitSoundToClient(x, soundre, SOUND_FROM_PLAYER, SNDCHAN_AUTO, SNDLEVEL_GUNFIRE, _, level);
	}
}