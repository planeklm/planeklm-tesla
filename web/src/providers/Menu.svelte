<script lang="ts">
    import { crossfade } from 'svelte/transition';
    export const [send, receive] = crossfade({ duration: 500 });
    import Icon from '@iconify/svelte';
    import { SendEvent, ReceiveEvent } from '@utils/eventsHandlers';
    import { onDestroy } from 'svelte';

    let isCarAhead = false;
    let speed = 0;
    let gear = 'D';
    let batteryLevel = 25;
    let leftBlinker = false;
    let rightBlinker = false;
    let blinkerVisible = true;

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

    ReceiveEvent<boolean>('setVisible', visibilityHandler);
    ReceiveEvent<number>('updateSpeed', speedHandler);

    ReceiveEvent<string>('updateBlinkers', (state: string) => {
        switch (state) {
            case '0':
                leftBlinker = rightBlinker = false;
                break;
            case '1':
                leftBlinker = true;
                rightBlinker = false;
                break;
            case '2':
                leftBlinker = false;
                rightBlinker = true;
                break;
            default:
                leftBlinker = rightBlinker = true;
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

    ReceiveEvent<boolean>('autopilotStatus', (status: boolean) => {
        isAutoPilotActive = status;
        if (!status) tripTime = 0;
    });

    ReceiveEvent<number>('updateTripTime', (time: number) => {
        tripTime = time;
    });
</script>

<div class="grid">
    <div class="items-center justify-center">
        <div
            class="fixed bottom-4 right-4 bg-[#fbfafb] rounded-3xl shadow-md w-[300px] h-[320px] p-4"
        >
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
                <div class="flex justify-center gap-4 mt-4 font-semibold">
                    <p class="text-black text-lg font-semibold">
                        {batteryLevel}%
                    </p>
                    <p class="text-black text-lg font-semibold">{gear}</p>
                    {#if isAutoPilotActive}
                        <p class="text-black text-xl">
                            {formatTime(tripTime)}
                        </p>
                    {:else}
                        <p class="text-black text-lg">AP Inactive</p>
                    {/if}
                </div>
                <div class="relative h-60 w-60 mx-auto mt-6 mb-4">
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
    <!--
    <div class="items-center justify-center">
        <div
            class="fixed bottom-4 right-[325px] bg-[#fbfafb] rounded-3xl shadow-md w-[200px] h-[320px] p-4"
        >
            <div class="text-center mt-4"></div>
        </div>
    </div>
    -->
</div>
