# Chapter 7 — The Stampede

**Time:** ~25 min  
**Prev:** [Chapter 6](06-unthinkable-error.md) · **Next:** [Chapter 8 — The Final Showdown](08-final-showdown.md)

---

Markets are in freefall. The Head of Quant needs the calculation fleet scaled
from one engine to many — **identical** machines, on demand. Forge a golden
template and stamp them out.

---

## Task 1: Forge the golden template

**Advanced → Templates → Create**:

| Field | Value |
|---|---|
| Namespace | `harvester-public` |
| Template Name | `prod-basic` |
| CPU | `1` |
| Memory | `1 GiB` |
| SSH Key | `prod/default` |
| Volume image | your Chapter 2 cloud image |
| Network | `prod/service` |
| Label | `stage=prod` |
| User Data Template | `prod/prod` (if present) |

**Create**.

---

## Task 2: Stamp the initial fleet

From the template → **Create Virtual Machine** (or Virtual Machines → Create
from template):

| Name | Namespace |
|---|---|
| `calc-engine-01` | `prod` |
| `calc-engine-02` | `prod` |
| `calc-engine-03` | `prod` |

Wait until all three are **Running**.

---

## Task 3: Scale under pressure

Create two more from the same template:

| Name |
|---|
| `calc-engine-04` |
| `calc-engine-05` |

Confirm five identical engines in `prod`.

---

## Task 4: Stand the fleet down

When the spike passes, delete `calc-engine-04` and `calc-engine-05` (and
optionally the rest) so capacity returns to the bank. The **template** remains
— the next spike is a few clicks, not a ticket queue.

---

## Checkpoint

- [ ] Template `harvester-public/prod-basic` exists
- [ ] At least three VMs created from it
- [ ] Scaled to five, then scaled back

**Next:** [Chapter 8 — The Final Showdown](08-final-showdown.md)
