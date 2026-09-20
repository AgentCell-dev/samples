// GET / serves the marker line every sample here serves. A route handler, not a page component,
// because the contract is "one exact plain-text line" -- a page.tsx would come back wrapped in
// <html><body>. There is no page.tsx at the app root for the same reason (App Router refuses a
// route.ts and a page.tsx on the same segment); see app/about/page.tsx for an ordinary page.
import { NextResponse } from "next/server";
import { marker } from "@/lib/marker";

export const dynamic = "force-dynamic";

export async function GET() {
  const body = `agentcell sample: nextjs-app ${marker()}\n`;
  return new NextResponse(body, {
    status: 200,
    headers: { "Content-Type": "text/plain; charset=utf-8" },
  });
}
