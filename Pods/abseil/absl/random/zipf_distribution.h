// Copyright 2017 The Abseil Authors.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#ifndef ABSL_RANDOM_ZIPF_DISTRIBUTION_H_
#define ABSL_RANDOM_ZIPF_DISTRIBUTION_H_

#include <cassert>
#include <cmath>
#include <istream>
#include <limits>
#include <ostream>
#include <type_traits>

#include "absl/random/internal/iostream_state_saver.h"
#include "absl/random/internal/traits.h"
#include "absl/random/uniform_real_distribution.h"

namespace absl {
ABSL_NAMESPACE_BEGIN

// absl::zipf_distribution produces random integer-values in the range [0, k],
// distributed according to the unnormalized discrete probability function:
//
//  P(x) = (v + x) ^ -q
//
// The parameter `v` must be greater than 0 and the parameter `q` must be
// greater than 1. If either of these parameters take invalid values then the
// behavior is undefined.
//
// IntType is the result_type generated by the generator. It must be of integral
// type; a static_assert ensures this is the case.
//
// The implementation is based on W.Hormann, G.Derflinger:
//
// "Rejection-Inversion to Generate Variates from Monotone Discrete
// Distributions"
//
// http://eeyore.wu-wien.ac.at/papers/96-04-04.wh-der.ps.gz
//
template <typename IntType = int>
class zipf_distribution {
 public:
  using result_type = IntType;

  class param_type {
   public:
    using distribution_type = zipf_distribution;

    // Preconditions: k > 0, v > 0, q > 1
    // The precondidtions are validated when NDEBUG is not defined via
    // a pair of assert() directives.
    // If NDEBUG is defined and either or both of these parameters take invalid
    // values, the behavior of the class is undefined.
    explicit param_type(result_type k = (std::numeric_limits<IntType>::max)(),
                        double q = 2.0, double v = 1.0);

    result_type k() const { return k_; }
    double q() const { return q_; }
    double v() const { return v_; }

    friend bool operator==(const param_type& a, const param_type& b) {
      return a.k_ == b.k_ && a.q_ == b.q_ && a.v_ == b.v_;
    }
    friend bool operator!=(const param_type& a, const param_type& b) {
      return !(a == b);
    }

   private:
    friend class zipf_distribution;
    inline double h(double x) const;
    inline double hinv(double x) const;
    inline double compute_s() const;
    inline double pow_negative_q(double x) const;

    // Parameters here are exactly the same as the parameters of Algorithm ZRI
    // in the paper.
    IntType k_;
    double q_;
    double v_;

    double one_minus_q_;  // 1-q
    double s_;
    double one_minus_q_inv_;  // 1 / 1-q
    double hxm_;              // h(k + 0.5)
    double hx0_minus_hxm_;    // h(x0) - h(k + 0.5)

    static_assert(random_internal::IsIntegral<IntType>::value,
                  "Class-template absl::zipf_distribution<> must be "
                  "parameterized using an integral type.");
  };

  zipf_distribution()
      : zipf_distribution((std::numeric_limits<IntType>::max)()) {}

  explicit zipf_distribution(result_type k, double q = 2.0, double v = 1.0)
      : param_(k, q, v) {}

  explicit zipf_distribution(const param_type& p) : param_(p) {}

  void reset() {}

  template <typename URBG>
  result_type operator()(URBG& g) {  // NOLINT(runtime/references)
    return (*this)(g, param_);
  }

  template <typename URBG>
  result_type operator()(URBG& g,  // NOLINT(runtime/references)
                         const param_type& p);

  result_type k() const { return param_.k(); }
  double q() const { return param_.q(); }
  double v() const { return param_.v(); }

  param_type param() const { return param_; }
  void param(const param_type& p) { param_ = p; }

  result_type(min)() const { return 0; }
  result_type(max)() const { return k(); }

  friend bool operator==(const zipf_distribution& a,
                         const zipf_distribution& b) {
    return a.param_ == b.param_;
  }
  friend bool operator!=(const zipf_distribution& a,
                         const zipf_distribution& b) {
    return a.param_ != b.param_;
  }

 private:
  param_type param_;
};

// --------------------------------------------------------------------------
// Implementation details follow
// --------------------------------------------------------------------------

template <typename IntType>
zipf_distribution<IntType>::param_type::param_type(
    typename zipf_distribution<IntType>::result_type k, double q, double v)
    : k_(k), q_(q), v_(v), one_minus_q_(1 - q) {
  assert(q > 1);
  assert(v > 0);
  assert(k > 0);
  one_minus_q_inv_ = 1 / one_minus_q_;

  // Setup for the ZRI algorithm (pg 17 of the paper).
  // Compute: h(i max) => h(k + 0.5)
  constexpr double kMax = 18446744073709549568.0;
  double kd = static_cast<double>(k);
  // TODO(absl-team): Determine if this check is needed, and if so, add a test
  // that fails for k > kMax
  if (kd > kMax) {
    // Ensure that our maximum value is capped to a value which will
    // round-trip back through double.
    kd = kMax;
  }
  hxm_ = h(kd + 0.5);

  // Compute: h(0)
  const bool use_precomputed = (v == 1.0 && q == 2.0);
  const double h0x5 = use_precomputed ? (-1.0 / 1.5)  // exp(-log(1.5))
                                      : h(0.5);
  const double elogv_q = (v_ == 1.0) ? 1 : pow_negative_q(v_);

  // h(0) = h(0.5) - exp(log(v) * -q)
  hx0_minus_hxm_ = (h0x5 - elogv_q) - hxm_;

  // And s
  s_ = use_precomputed ? 0.46153846153846123 : compute_s();
}

template <typename IntType>
double zipf_distribution<IntType>::param_type::h(double x) const {
  // std::exp(one_minus_q_ * std::log(v_ + x)) * one_minus_q_inv_;
  x += v_;
  return (one_minus_q_ == -1.0)
             ? (-1.0 / x)  // -exp(-log(x))
             : (std::exp(std::log(x) * one_minus_q_) * one_minus_q_inv_);
}

template <typename IntType>
double zipf_distribution<IntType>::param_type::hinv(double x) const {
  // std::exp(one_minus_q_inv_ * std::log(one_minus_q_ * x)) - v_;
  return -v_ + ((one_minus_q_ == -1.0)
                    ? (-1.0 / x)  // exp(-log(-x))
                    : std::exp(one_minus_q_inv_ * std::log(one_minus_q_ * x)));
}

template <typename IntType>
double zipf_distribution<IntType>::param_type::compute_s() const {
  // 1 - hinv(h(1.5) - std::exp(std::log(v_ + 1) * -q_));
  return 1.0 - hinv(h(1.5) - pow_negative_q(v_ + 1.0));
}

template <typename IntType>
double zipf_distribution<IntType>::param_type::pow_negative_q(double x) const {
  // std::exp(std::log(x) * -q_);
  return q_ == 2.0 ? (1.0 / (x * x)) : std::exp(std::log(x) * -q_);
}

template <typename IntType>
template <typename URBG>
typename zipf_distribution<IntType>::result_type
zipf_distribution<IntType>::operator()(
    URBG& g, const param_type& p) {  // NOLINT(runtime/references)
  absl::uniform_real_distribution<double> uniform_double;
  double k;
  for (;;) {
    const double v = uniform_double(g);
    const double u = p.hxm_ + v * p.hx0_minus_hxm_;
    const double x = p.hinv(u);
    k = rint(x);              // std::floor(x + 0.5);
    if (k > static_cast<double>(p.k())) continue;  // reject k > max_k
    if (k - x <= p.s_) break;
    const double h = p.h(k + 0.5);
    const double r = p.pow_negative_q(p.v_ + k);
    if (u >= h - r) break;
  }
  IntType ki = static_cast<IntType>(k);
  assert(ki <= p.k_);
  return ki;
}

template <typename CharT, typename Traits, typename IntType>
std::basic_ostream<CharT, Traits>& operator<<(
    std::basic_ostream<CharT, Traits>& os,  // NOLINT(runtime/references)
    const zipf_distribution<IntType>& x) {
  using stream_type =
      typename random_internal::stream_format_type<IntType>::type;
  auto saver = random_internal::make_ostream_state_saver(os);
  os.precision(random_internal::stream_precision_helper<double>::kPrecision);
  os << static_cast<stream_type>(x.k()) << os.fill() << x.q() << os.fill()
     << x.v();
  return os;
}

template <typename CharT, typename Traits, typename IntType>
std::basic_istream<CharT, Traits>& operator>>(
    std::basic_istream<CharT, Traits>& is,  // NOLINT(runtime/references)
    zipf_distribution<IntType>& x) {        // NOLINT(runtime/references)
  using result_type = typename zipf_distribution<IntType>::result_type;
  using param_type = typename zipf_distribution<IntType>::param_type;
  using stream_type =
      typename random_internal::stream_format_type<IntType>::type;
  stream_type k;
  double q;
  double v;

  auto saver = random_internal::make_istream_state_saver(is);
  is >> k >> q >> v;
  if (!is.fail()) {
    x.param(param_type(static_cast<result_type>(k), q, v));
  }
  return is;
}

ABSL_NAMESPACE_END
}  // namespace absl

#endif  // ABSL_RANDOM_ZIPF_DISTRIBUTION_H_
