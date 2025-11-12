package xoshiro256pp

/*
 Based on [xoshiro256++](https://prng.di.unimi.it/xoshiro256plusplus.c)
 by David Blackman and Sebastiano Vigna

 xoshiro256++ and Splitmix64 original license:
    To the extent possible under law, the author has dedicated all copyright
    and related and neighboring rights to this software to the public domain
    worldwide.

    Permission to use, copy, modify, and/or distribute this software for any
    purpose with or without fee is hereby granted.

    THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
    WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
    MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
    ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
    WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
    ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR
    IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
*/

import "base:intrinsics"
import "base:runtime"
import "core:math/bits"

State :: distinct [4]u64

@(private)
@(thread_local)
thread_state: State

@(require_results)
read_u64 :: proc "contextless" (state: ^State) -> u64 {
	result := bits.rotate_left64(state[0] + state[3], 23) + state[0]
	t := state[1] << 17
	state[2] ~= state[0]
	state[3] ~= state[1]
	state[1] ~= state[2]
	state[0] ~= state[3]
	state[2] ~= t
	state[3] = bits.rotate_left64(state[3], 45)

	return result
}

@(require_results)
new_state :: proc "contextless" (seed: u64 = 0) -> (state: State) {

	// based on [Splitmix64](https://prng.di.unimi.it/splitmix64.c) by Sebastiano Vigna
	splitmix_next :: proc "contextless" (x: u64) -> u64 {
		z := x + 0x9e3779b97f4a7c15
		z = (z ~ (z >> 30)) * 0xbf58476d1ce4e5b9
		z = (z ~ (z >> 27)) * 0x94d049bb133111eb
		return z ~ (z >> 31)
	}

	seed := seed
	if seed == 0 {
		seed = u64(intrinsics.read_cycle_counter())
	}
	for &v in state {
		seed = splitmix_next(seed)
		v = seed
	}

	return
}

@(private)
rand_proc :: proc(data: rawptr, mode: runtime.Random_Generator_Mode, p: []byte) {
	state: ^State = ---
	if data == nil {
		state = &thread_state
	} else {
		state = cast(^State)data
	}

	switch mode {
	case .Read:
		if state^ == {0, 0, 0, 0} {
			state^ = new_state()
		}

		switch len(p) {
		case size_of(u64):
			// Fast path for a 64-bit destination.
			intrinsics.unaligned_store((^u64)(raw_data(p)), read_u64(state))
		case:
			// All other cases.
			pos := i8(0)
			val := u64(0)
			for &v in p {
				if pos == 0 {
					val = read_u64(state)
					pos = 8
				}
				v = byte(val)
				val >>= 8
				pos -= 1
			}
		}
	case .Reset:
		switch len(p) {
		case size_of(u64):
			state^ = new_state((^u64)(raw_data(p))^)
		case size_of(State):
			runtime.mem_copy_non_overlapping(state, raw_data(p), size_of(State))
		case:
			panic("Invalid seed size for xoshiro256++ RNG reset.")
		}
	case .Query_Info:
		assert(len(p) >= size_of(runtime.Random_Generator_Query_Info))
		info := (^runtime.Random_Generator_Query_Info)(raw_data(p))
		info^ = {.Uniform, .Resettable}
	}
}

@(require_results)
get_state :: proc(gen: ^runtime.Random_Generator) -> ^State {
	assert(gen.procedure == rand_proc, "Wrong generator")
	if gen.data != nil {return cast(^State)gen.data} else {return &thread_state}
}

@(require_results)
random_generator :: proc "contextless" (state: ^State = nil) -> runtime.Random_Generator {
	return {data = state, procedure = rand_proc}
}
