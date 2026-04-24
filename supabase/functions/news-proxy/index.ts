/**
 * news-proxy — Edge Function that proxies NewsAPI calls so the API key
 * never lives in the Flutter client.
 *
 * POST body: { query: string, pageSize?: number, page?: number }
 * Response:  NewsAPI /v2/everything JSON (articles array + totalResults)
 *
 * Secret required: NEWS_API_KEY  (set via: supabase secrets set NEWS_API_KEY=...)
 */

import { serve } from 'https://deno.land/std@0.177.0/http/server.ts';

const CORS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: CORS });
  }

  try {
    const { query = 'health seniors', pageSize = 10, page = 1 } = await req.json();

    const apiKey = Deno.env.get('NEWS_API_KEY');
    if (!apiKey) {
      return new Response(JSON.stringify({ articles: [], totalResults: 0 }), {
        headers: { ...CORS, 'Content-Type': 'application/json' },
        status: 200,
      });
    }

    const url = new URL('https://newsapi.org/v2/everything');
    url.searchParams.set('q', query);
    url.searchParams.set('pageSize', String(pageSize));
    url.searchParams.set('page', String(page));
    url.searchParams.set('language', 'en');
    url.searchParams.set('sortBy', 'publishedAt');
    url.searchParams.set('apiKey', apiKey);

    const resp = await fetch(url.toString());
    const data = await resp.json();

    return new Response(JSON.stringify(data), {
      headers: { ...CORS, 'Content-Type': 'application/json' },
      status: 200,
    });
  } catch (err) {
    return new Response(JSON.stringify({ error: String(err), articles: [], totalResults: 0 }), {
      headers: { ...CORS, 'Content-Type': 'application/json' },
      status: 200, // Always 200 — Flutter treats non-200 as hard error
    });
  }
});
