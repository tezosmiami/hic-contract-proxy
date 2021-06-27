from pytezos import MichelsonRuntimeError
from map_base import MapBaseCase


class MapInteractionTest(MapBaseCase):
    def test_interactions(self):
        # Factory test:
        self._create_collab(self.admin, self.originate_params)

        # Test mint call from admin succeed:
        self._mint_call(self.admin)

        # Test mint call without admin role failed:
        with self.assertRaises(MichelsonRuntimeError) as cm:
            self._mint_call(self.p2)
        self.assertTrue('Entrypoint can call only administrator' in str(cm.exception))

        # Test swap call from admin succeed:
        self._swap_call(self.admin)

        # Testing that calling swap from non-administrator address is not possible:
        with self.assertRaises(MichelsonRuntimeError) as cm:
            self._swap_call(self.p2)
        self.assertTrue('Entrypoint can call only administrator' in str(cm.exception))

        # Test cancel swap call from admin succeed:
        self._cancel_swap_call(self.admin)

        # Testing that calling cancel swap from non-administrator address is not possible:
        with self.assertRaises(MichelsonRuntimeError) as cm:
            self._cancel_swap_call(self.tips)
        self.assertTrue('Entrypoint can call only administrator' in str(cm.exception))

        # Test collect call from admin succeed:
        self._collect_call(self.admin)

        # Testing that calling collect from non-administrator address is not possible:
        with self.assertRaises(MichelsonRuntimeError) as cm:
            self._collect_call(self.tips)
        self.assertTrue('Entrypoint can call only administrator' in str(cm.exception))

        # Test curate call from admin succeed:
        self._curate_call(self.admin)

        # Testing that curate call from non-administrator address is not possible:
        with self.assertRaises(MichelsonRuntimeError) as cm:
            self._curate_call(self.tips)
        self.assertTrue('Entrypoint can call only administrator' in str(cm.exception))

        # Default entrypoint tests with value that can be easy splitted:
        self._default_call(self.tips, 1000)

        # Default entrypoint tests with value that hard to split equally:
        self._default_call(self.tips, 337)

        # Default entrypoint tests with value that very hard to split:
        self._default_call(self.tips, 1)

        # Default entrypoint tests with very big value (100 bln tez):
        self._default_call(self.tips, 10**17)

        # Collab with very crazy big shares:
        crazy_params = {
            self.p1: {'share': 10**35, 'isCore': True},
            self.p2: {'share': 10**35, 'isCore': True},
            self.tips: {'share': 10**35, 'isCore': True}
        }

        self._create_collab(self.p2, crazy_params)
        self._default_call(self.tips, 10**17)

        # Mint from admin address (now admin is p2):
        self._mint_call(self.p2)
        with self.assertRaises(MichelsonRuntimeError) as cm:
            self._mint_call(self.admin)
        self.assertTrue('Entrypoint can call only administrator' in str(cm.exception))

        # Collab with 1 participant can be created with only 1 share,
        # and we allow to have participants with 0 share (why not?):
        single = {
            self.p1: {'share': 1, 'isCore': True},
            self.p2: {'share': 0, 'isCore': True},
        }
        self._create_collab(self.admin, single)
        self._default_call(self.tips, 1000)

        # Collab can't be created with only 0 shares:
        with self.assertRaises(MichelsonRuntimeError) as cm:
            twin = {
                self.p1: {'share': 0, 'isCore': True},
                self.p2: {'share': 0, 'isCore': True},
            }
            self._create_collab(self.admin, twin)
        msg = 'Sum of the shares should be more than 0n'
        self.assertTrue(msg in str(cm.exception))

        # Collab with zero-core can't be created:
        with self.assertRaises(MichelsonRuntimeError) as cm:
            no_core = {
                self.p1: {'share': 1, 'isCore': False},
                self.p2: {'share': 1, 'isCore': False},
            }
            self._create_collab(self.admin, no_core)
        msg = 'Collab contract should have at least one core'
        self.assertTrue(msg in str(cm.exception))

        # TODO: Collab with too many participants can't be created:
        # TODO: NEED TO TEST LIMIT
        # TODO: need to make MORE tests
