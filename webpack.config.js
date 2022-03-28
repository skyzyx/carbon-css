const devMode = process.env.NODE_ENV !== 'production';
const path = require('path');
const supportedLocales = [ 'en' ];

// Require.js syntax
const AssetsPlugin = require('assets-webpack-plugin');
const Autoprefixer = require('autoprefixer');
const CompressionPlugin = require('compression-webpack-plugin');
const CssMinimizerPlugin = require('css-minimizer-webpack-plugin');
const MiniCssExtractPlugin = require('mini-css-extract-plugin');
const SriPlugin = require('webpack-subresource-integrity');
const TerserJSPlugin = require('terser-webpack-plugin');
const WebPack = require('webpack');

//------------------------------------------------------------------------------

const miniCssLoader = {
  loader: MiniCssExtractPlugin.loader,
  options: {}
};

//------------------------------------------------------------------------------

module.exports = {
  mode: "production",
  optimization: {
    minimize: true,
    minimizer: [
      '...',
      new TerserJSPlugin({}),
      new CssMinimizerPlugin(),
    ],
  },
  plugins: [
    new WebPack.ContextReplacementPlugin(
      /date\-fns[\/\\]/,
      new RegExp(`[/\\\\](${ supportedLocales.join('|') })[/\\\\]`)
    ),
    new CompressionPlugin(),
    new MiniCssExtractPlugin({
      filename: 'carbon.css',
      chunkFilename: 'carbon.css',
    }),
    new AssetsPlugin({
      filename: 'subresource-integrity.json',
      path: path.join(__dirname, './dist'),
      integrity: true,
      prettyPrint: true,
    }),
    Autoprefixer,
  ],
  module: {
    rules: [
      {
        test: /\.js$/i,
        exclude: /node_modules/,
      },
      {
        test: /\.less$/,
        use: [
          miniCssLoader,
          { loader: 'css-loader' },
          { loader: 'less-loader' },
        ],
      },
      {
        test: /\.css$/,
        use: [
          miniCssLoader,
          { loader: 'css-loader' },
        ],
      },
    ],
  },
  resolve: {
    modules: [ path.resolve(__dirname, 'src'), 'node_modules' ],
  },
  entry: {
    styles: path.resolve(__dirname, 'src/'),
  },
  output: {
    crossOriginLoading: 'anonymous',
  }
};
