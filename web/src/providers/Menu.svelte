<script lang="ts">
    import { crossfade, fade } from 'svelte/transition';
    export const [send, receive] = crossfade({ duration: 1000 });
    import Icon from '@iconify/svelte';
    import { ReceiveEvent } from '@utils/eventsHandlers';
    import { onDestroy } from 'svelte';

    let isCarAhead = false;
    let speed = 0;
    let gear = 'D';
    let batteryLevel = 0;
    let leftBlinker = false;
    let rightBlinker = false;
    let blinkerVisible = true;
    let isVisible = true;

    let blinkerInterval: ReturnType<typeof setInterval> | undefined;

    function toggleBlinkerVisibility() {
        blinkerVisible = !blinkerVisible;
    }

    $: if (leftBlinker || rightBlinker) {
        if (!blinkerInterval) {
            blinkerInterval = setInterval(toggleBlinkerVisibility, 500);
        }
    } else {
        if (blinkerInterval) {
            clearInterval(blinkerInterval);
            blinkerInterval = undefined;
            blinkerVisible = true;
        }
    }

    const visibilityHandler = (bool: boolean) => {
        if (isCarAhead !== bool) {
            isCarAhead = bool;
        }
    };

    let speedUpdateTimeout: number | null = null;
    const speedHandler = (currentSpeed: number) => {
        if (speedUpdateTimeout) clearTimeout(speedUpdateTimeout);

        speedUpdateTimeout = setTimeout(() => {
            speed = currentSpeed;
            speedUpdateTimeout = null;
        }, 100) as unknown as number;
    };

    ReceiveEvent<boolean>('setMenuVisible', (bool: boolean) => {
        isVisible = bool;
    });

    ReceiveEvent<boolean>('setCarAheadVisible', visibilityHandler);

    ReceiveEvent<number>('updateSpeed', speedHandler);

    ReceiveEvent<string>('updateBlinkers', (state: string) => {
        if (state == '0') {
            leftBlinker = rightBlinker = false;
        } else if (state == '1') {
            leftBlinker = true;
            rightBlinker = false;
        } else if (state == '2') {
            leftBlinker = false;
            rightBlinker = true;
        }
    });

    ReceiveEvent<number>('updateGears', (state: number) => {
        if (state == 0) {
            gear = 'R';
        } else if (state <= 1) {
            gear = 'D';
        }
    });

    ReceiveEvent<number>('updateBattery', (level: number) => {
        batteryLevel = level;
    });

    onDestroy(() => {
        if (speedUpdateTimeout) clearTimeout(speedUpdateTimeout);
        if (blinkerInterval) clearInterval(blinkerInterval);
    });

    let tripTime = 0;
    let isAutoPilotActive = false;

    function formatTime(seconds: number): string {
        const hours = Math.floor(seconds / 3600);
        const minutes = Math.floor((seconds % 3600) / 60);
        const secs = Math.floor(seconds % 60);
        return `${hours}h ${minutes}m ${secs}s`;
    }

    function getBatteryColor(level: number): string {
        if (level <= 20) return '#FF5252';
        if (level <= 50) return '#FFC107';
        return '#4CAF50';
    }

    ReceiveEvent<boolean>('autopilotStatus', (status: boolean) => {
        isAutoPilotActive = status;
        if (!status) tripTime = 0;
    });

    ReceiveEvent<number>('updateTripTime', (time: number) => {
        tripTime = time;
    });
</script>

{#if isVisible}
    <div
        class="fixed bottom-4 right-4 w-[300px] h-[320px]"
        in:fade={{ duration: 300, delay: 400 }}
        out:fade={{ duration: 300 }}
    >
        <div class="bg-[#fbfafb] rounded-3xl shadow-md w-full h-full p-4">
            <div class="text-center mt-4">
                <h1 class="text-black text-7xl font-bold">{speed}</h1>
                <p class="text-black text-lg font-bold mt-1">KM/H</p>
                <div class="flex justify-center gap-5">
                    <Icon
                        class="text-3xl"
                        style="color: {leftBlinker && blinkerVisible
                            ? '#4CAF50'
                            : 'black'}"
                        icon="mdi:arrow-left-bold"
                    />
                    <Icon
                        class="text-3xl"
                        style="color: {rightBlinker && blinkerVisible
                            ? '#4CAF50'
                            : 'black'}"
                        icon="mdi:arrow-right-bold"
                    />
                </div>
                <div class="flex justify-center items-center gap-2 mt-4">
                    <div
                        class="w-24 h-4 bg-gray-200 rounded-full overflow-hidden"
                    >
                        <div
                            class="h-full rounded-full"
                            style="width: {batteryLevel}%; background-color: {getBatteryColor(
                                batteryLevel,
                            )}"
                        ></div>
                    </div>
                    <p
                        class="text-black text-lg font-semibold"
                        style="color: {getBatteryColor(batteryLevel)}"
                    >
                        {batteryLevel}%
                    </p>
                </div>

                <div class="flex justify-center gap-4 mt-2 font-semibold">
                    <p class="text-black text-lg font-semibold">{gear}</p>
                    {#if isAutoPilotActive}
                        <p class="text-black text-xl">
                            {formatTime(tripTime)}
                        </p>
                    {:else}
                        <p class="text-black text-lg">AP Inactive</p>
                    {/if}
                </div>
                <div class="relative h-60 w-60 mx-auto mt-4 mb-4">
                    {#if isCarAhead && isAutoPilotActive}
                        <img
                            class="absolute inset-0 w-full h-full object-contain"
                            src="teslacaraheadautopilot.png"
                            alt="Car ahead"
                        />
                    {:else if isCarAhead && !isAutoPilotActive}
                        <img
                            class="absolute inset-0 w-full h-full object-contain"
                            src="teslacaraheadnoautopilot.png"
                            alt="No car ahead"
                        />
                    {:else if !isCarAhead && isAutoPilotActive}
                        <img
                            class="absolute inset-0 w-full h-full object-contain"
                            src="teslanocaraheadautopilot.png"
                            alt="Car ahead"
                        />
                    {:else}
                        <img
                            class="absolute inset-0 w-full h-full object-contain"
                            src="teslanocaraheadnoautopilot.png"
                            alt="No car ahead"
                        />
                    {/if}
                </div>
            </div>
        </div>
    </div>
{/if}
