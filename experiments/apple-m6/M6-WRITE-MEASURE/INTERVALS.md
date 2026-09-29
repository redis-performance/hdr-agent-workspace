# Same-binary qualification intervals

All entries are paired conservative 95% intervals in percent for the same baseline
executable in both arms. These are noise measurements, not candidate speedups.
Pass requires the entire interval to lie within [-1%, +1%]. Six balanced pairs
per case; no extension, case removal or pooling across protocols.

| Case | W1-protocol A/A interval | W2-protocol A/A interval |
|---|---:|---:|
| atomic_coarse_sig1 | [-3.566, 2.414] FAIL | [-1.717, 1.244] FAIL |
| atomic_coarse_sig2 | [-1.698, 1.051] FAIL | [-0.768, 2.206] FAIL |
| atomic_coarse_sig5 | [-3.239, 1.625] FAIL | [-3.062, 2.714] FAIL |
| atomic_constant | [0.184, 2.535] FAIL | [-2.902, 3.627] FAIL |
| atomic_correlated | [-3.535, 1.988] FAIL | [-7.262, 5.971] FAIL |
| atomic_extremes | [-3.074, 2.394] FAIL | [-1.140, 5.952] FAIL |
| atomic_iid | [-3.232, 1.994] FAIL | [-2.359, 0.834] FAIL |
| atomic_increasing | [-2.176, 4.019] FAIL | [-4.766, 6.494] FAIL |
| atomic_mixed_validity | [-5.889, 4.233] FAIL | [-4.048, 2.224] FAIL |
| atomic_offset_mixed | [-2.937, 1.508] FAIL | [-2.123, 1.529] FAIL |
| atomic_offset_neg | [-1.426, 1.460] FAIL | [-0.203, 1.156] FAIL |
| atomic_offset_pos | [-1.790, 1.364] FAIL | [-1.059, -0.350] FAIL |
| atomic_offset_wrap_neg | [-1.187, 1.223] FAIL | [-1.098, 0.010] FAIL |
| atomic_offset_wrap_pos | [-0.541, 1.245] FAIL | [-2.046, 1.949] FAIL |
| atomic_reject_above | [-17.489, 36.522] FAIL | [-31.683, 6.154] FAIL |
| atomic_reject_negative | [-14.846, 11.401] FAIL | [-27.016, 35.031] FAIL |
| write_coarse_sig1 | [-0.605, 1.581] FAIL | [-1.033, 2.204] FAIL |
| write_coarse_sig2 | [-0.755, 1.195] FAIL | [-0.220, 0.675] PASS |
| write_coarse_sig5 | [-0.683, 0.393] PASS | [-0.625, 0.949] PASS |
| write_constant | [-0.490, 0.622] PASS | [-0.799, 0.235] PASS |
| write_correlated | [-0.975, 0.953] PASS | [-1.856, 1.398] FAIL |
| write_extremes | [-0.542, 0.568] PASS | [-0.595, 0.121] PASS |
| write_iid | [-0.669, 0.699] PASS | [-0.901, 0.617] PASS |
| write_increasing | [-0.872, 2.086] FAIL | [-0.812, 1.603] FAIL |
| write_mixed_validity | [-1.228, 0.438] FAIL | [-5.292, 3.392] FAIL |
| write_offset_mixed | [-0.600, 1.081] FAIL | [-0.996, 1.332] FAIL |
| write_offset_neg | [-0.363, 1.481] FAIL | [-1.487, 0.401] FAIL |
| write_offset_pos | [-1.134, 0.657] FAIL | [-1.286, 0.729] FAIL |
| write_offset_wrap_neg | [-0.320, 0.725] PASS | [-0.579, 1.180] FAIL |
| write_offset_wrap_pos | [-1.797, 1.571] FAIL | [-0.409, 0.506] PASS |
| write_reject_above | [-15.976, 47.488] FAIL | [-9.786, 42.244] FAIL |
| write_reject_negative | [-20.315, 16.816] FAIL | [-39.163, 22.717] FAIL |
