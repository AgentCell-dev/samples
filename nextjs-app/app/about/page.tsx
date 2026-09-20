// An ordinary App Router page, the counterpart to the root's plain-text route.ts -- the
// `make check-nextjs-app` target asserts this one returns 200 too, as proof the app has more
// than the one hand-rolled route.
import { marker } from "@/lib/marker";

export const dynamic = "force-dynamic";

export default function AboutPage() {
  return (
    <main>
      <h1>agentcell sample: nextjs-app</h1>
      <p>marker: {marker()}</p>
      <p>
        This is <code>/about</code>, an ordinary App Router page rendered server-side on every
        request (see <code>export const dynamic = &quot;force-dynamic&quot;</code> above) -- the
        counterpart to the root route, which is a plain-text route handler rather than a page.
      </p>
    </main>
  );
}
