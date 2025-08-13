#+private
package xoshiro256pp

import "core:math/rand"
import "core:testing"

rng := xoshiro_random_generator()
@(test)
correctness :: proc(t: ^testing.T) {
	context.random_generator = rng

	rand.reset(12069)
	testing.expect_value(t, rand.uint64(rng), 6822165461875935344)
	testing.expect_value(t, rand.uint64(rng), 8025991002992936016)
	testing.expect_value(t, rand.uint64(rng), 9803362972432194534)

	rand.reset(123456789)
	testing.expect_value(t, rand.uint64(rng), 11051695339995113534)
	testing.expect_value(t, rand.uint64(rng), 4988023938500368323)
	testing.expect_value(t, rand.uint64(rng), 15893326098585791437)

	rand.reset(0xDEADBEEF)
	testing.expect_value(t, rand.uint64(rng), 3801289226785515695)
	testing.expect_value(t, rand.uint64(rng), 16228100807790805918)
	testing.expect_value(t, rand.uint64(rng), 14523653586541288138)

}

@(test)
reset :: proc(t: ^testing.T) {
	context.random_generator = rng

	// Test directly setting State
	state := State{1,2,3,4}
	rand.reset_bytes(([^]byte)(raw_data(state[:]))[:size_of(state)])
	testing.expect_value(t, ([^]u64)(rng.data)[:4][0], 1)
	testing.expect_value(t, ([^]u64)(rng.data)[:4][1], 2)
	testing.expect_value(t, ([^]u64)(rng.data)[:4][2], 3)
	testing.expect_value(t, ([^]u64)(rng.data)[:4][3], 4)

	// Test seeding with an int
	rand.reset(1)
	testing.expect_value(t, ([^]u64)(rng.data)[:4][0], 12823726057557579347)
	testing.expect_value(t, ([^]u64)(rng.data)[:4][1], 12497766466719209627)
	testing.expect_value(t, ([^]u64)(rng.data)[:4][2], 11400714814019112804)
	testing.expect_value(t, ([^]u64)(rng.data)[:4][3], 11400714819323198486)
}