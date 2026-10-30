"""The coverage-guided input search (wl3pc.oracle_search) on a fake game, without an emulator or ROM."""

import pickle

from wl3pc import oracle, oracle_search


class FakeMemory:
    def __init__(self):
        self.wram0 = bytearray(0x10000)
        self.banks = {1: bytearray(0x10000)}

    def __getitem__(self, key):
        if isinstance(key, tuple):
            return self.banks[key[0]][key[1]]
        return self.wram0[key]


class FakeGame:
    """One object slot whose OBJ_STATE counts the ticks Right was held: new coverage only comes
    from holding Right."""

    def __init__(self):
        self.memory = FakeMemory()
        self.held = set()
        self.memory.banks[1][oracle_search.OBJECTS_START] = 1  # active

    def button_press(self, button):
        self.held.add(button)

    def button_release(self, button):
        self.held.discard(button)

    def tick(self, count, render):
        for _ in range(count):
            if "right" in self.held:
                slot = oracle_search.OBJECTS_START + oracle_search.OBJ_STATE
                self.memory.banks[1][slot] = (self.memory.banks[1][slot] + 1) & 0xFF

    def save_state(self, file):
        file.write(pickle.dumps((bytes(self.memory.banks[1]), set(self.held))))

    def load_state(self, file):
        bank, held = pickle.loads(file.read())
        self.memory.banks[1][:] = bank
        self.held = set(held)

    def stop(self, save):
        pass


def test_search_seeds_and_names():
    assert oracle_search.search_seed("search-s1") == 1 and oracle_search.search_seed("search-s65535") == 65535
    for name in ("search", "search-s0", "search-s65536", "wander-s2"):
        assert oracle_search.search_seed(name) is None


def test_the_search_keeps_the_segments_that_reach_new_coverage_and_replays_the_same():
    held, seen = oracle_search.search(FakeGame(), 96, seed=3)
    assert len(held) == 96
    state_keys = {key for key in seen if key[0] >= 0}
    assert len(state_keys) > 40, "Right held most of the time: the counter goes far"
    assert oracle_search.search(FakeGame(), 96, seed=3) == (held, seen), "seeded"
    # A straight replay of the trace from the start sees what the search saw.
    replay = FakeGame()
    replayed = set(oracle_search.coverage_keys(replay))
    oracle.play(replay, oracle.make_trace(held, "test"), lambda tick: replayed.update(oracle_search.coverage_keys(replay)))
    assert replayed == seen
