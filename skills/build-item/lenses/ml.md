# Machine learning

**Seat:** when the diff changes a dataset, labels, features, training, a model file, a threshold,
or how a prediction is evaluated or acted on.

In the diff, look for:

- Leakage: information from the evaluation set, the future or the label reaching training or
  features.
- Training and serving doing the same step two ways, so the model meets inputs it never saw.
- A metric that does not measure what the item wants, or one number standing for slices that
  behave differently.
- A threshold or model swap with no before-and-after on the same held-out data.
- A claim of improvement from one run, with no variance and no baseline.

Prefer a simple model with a sound evaluation over a better model with a weak one.
