#+test
package xoshiro256pp

import "core:math/rand"
import "core:slice"
import "core:testing"

@(test)
test_determinism :: proc(t: ^testing.T) {
	context.random_generator = random_generator()
	rand.reset(t.seed)
	first_value := rand.int127()
	rand.reset(t.seed)
	second_value := rand.int127()

	testing.expect(t, first_value == second_value, "xoshiro RNG is non-deterministic.")
}

@(test)
test_default_seed_nonzero :: proc(t: ^testing.T) {
	context.random_generator = random_generator()
	rand.reset(0)
	value := rand.int127()

	testing.expect(t, value != 0, "xoshiro RNG with default seed produces zeroed state.")
}

@(test)
test_default_seed :: proc(t: ^testing.T) {
	context.random_generator = random_generator()
	rand.reset(0)
	first_value := rand.int127()
	rand.reset(0)
	second_value := rand.int127()

	testing.expect(
		t,
		first_value != second_value,
		"xoshiro RNG with default seed produces same values on reset.",
	)
}

@(test)
test_determinism_user_set :: proc(t: ^testing.T) {

	rng_state_1 := new_state(t.seed)
	rng_state_2 := new_state(t.seed)

	rng_1 := random_generator(&rng_state_1)
	rng_2 := random_generator(&rng_state_2)

	first_value, second_value: i128
	{
		context.random_generator = rng_1
		first_value = rand.int127()
	}
	{
		context.random_generator = rng_2
		second_value = rand.int127()
	}

	testing.expect(t, first_value == second_value, "User-set xoshiro RNG is non-deterministic.")
}

@(test)
test_no_collisions :: proc(t: ^testing.T) {
	context.random_generator = random_generator()
	samples: [1000]u64 = ---
	rand.reset(t.seed)

	for &s, i in samples {
		s = rand.uint64()
		testing.expect(t, !slice.contains(samples[:i], s), "xoshiro RNG produced a collision.")
	}
}

@(test)
test_query_info :: proc(t: ^testing.T) {
	rng := random_generator()
	info := rand.query_info(rng)

	testing.expect(t, .Uniform | .Resettable in info, "xoshiro RNG does not return correct info.")
}
