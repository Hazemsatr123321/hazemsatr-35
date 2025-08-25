import { serve } from 'https://deno.land/std@0.177.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import { corsHeaders } from '../_shared/cors.ts';

console.log('Update Reputation function initialized');

// Define seller tiers based on review count and average rating
const SELLER_TIERS = {
  POWER_SELLER: {
    name: 'Power Seller',
    minReviews: 201,
    minRating: 4.8,
  },
  TOP_SELLER: {
    name: 'Top Seller',
    minReviews: 51,
    minRating: 4.5,
  },
  RISING_STAR: {
    name: 'Rising Star',
    minReviews: 11,
    minRating: 4.0,
  },
  NEW_SELLER: {
    name: 'New Seller',
    minReviews: 0,
    minRating: 0,
  },
};

function determineSellerTier(reviewCount: number, avgRating: number): string {
  if (
    reviewCount >= SELLER_TIERS.POWER_SELLER.minReviews &&
    avgRating >= SELLER_TIERS.POWER_SELLER.minRating
  ) {
    return SELLER_TIERS.POWER_SELLER.name;
  }
  if (
    reviewCount >= SELLER_TIERS.TOP_SELLER.minReviews &&
    avgRating >= SELLER_TIERS.TOP_SELLER.minRating
  ) {
    return SELLER_TIERS.TOP_SELLER.name;
  }
  if (
    reviewCount >= SELLER_TIERS.RISING_STAR.minReviews &&
    avgRating >= SELLER_TIERS.RISING_STAR.minRating
  ) {
    return SELLER_TIERS.RISING_STAR.name;
  }
  return SELLER_TIERS.NEW_SELLER.name;
}

serve(async (req) => {
  // This is an example of a POST request handler
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const { record } = await req.json();
    const sellerId = record.seller_id;

    if (!sellerId) {
      throw new Error('seller_id is required in the request body');
    }

    const supabaseAdmin = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    );

    // 1. Fetch all reviews for the seller
    const { data: reviews, error: reviewsError } = await supabaseAdmin
      .from('reviews')
      .select('rating')
      .eq('seller_id', sellerId);

    if (reviewsError) throw reviewsError;

    // 2. Calculate the new average rating and review count
    const reviewCount = reviews.length;
    const totalRating = reviews.reduce((acc, review) => acc + review.rating, 0);
    const avgRating = reviewCount > 0 ? totalRating / reviewCount : 0;
    const roundedAvgRating = parseFloat(avgRating.toFixed(2)); // Round to 2 decimal places

    // 3. Determine the new seller tier
    const newTier = determineSellerTier(reviewCount, roundedAvgRating);

    // 4. Update the seller's profile
    const { error: updateError } = await supabaseAdmin
      .from('profiles')
      .update({
        reputation_score: roundedAvgRating,
        seller_tier: newTier,
      })
      .eq('id', sellerId);

    if (updateError) throw updateError;

    return new Response(JSON.stringify({ success: true, newTier }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 200,
    });
  } catch (error) {
    console.error('Error updating reputation:', error);
    return new Response(JSON.stringify({ error: error.message }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 400,
    });
  }
});
